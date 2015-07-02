###################################
#
# CFME Automate Method: AddChefTags
#
# Notes: This method uses a kinfe wrapper to bootstrap a Chef client
#
###################################
begin
  # Method for logging
  def log(level, message)
    @method = 'AddChefTags'
    $evm.log(level, "#{@method}: #{message}")
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
  end
  
  # basic retry logic
  def retry_method(retry_time=1.minute)
    log(:info, "Sleeping for #{retry_time} seconds")
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = retry_time
    exit MIQ_OK
  end

  # process_tags - Dynamically create categories and tags
  def process_tags( category, category_description, single_value, tag, tag_description )
    # Convert to lower case and replace all non-word characters with underscores
    category_name = category.to_s.downcase.gsub(/\W/, '_')
    tag_name = tag.to_s.downcase.gsub(/\W/, '_')
    log(:info, "Converted category name:<#{category_name}> Converted tag name: <#{tag_name}>")
    # if the category exists else create it
    unless $evm.execute('category_exists?', category_name)
      log(:info, "Category <#{category_name}> doesn't exist, creating category")
      $evm.execute('category_create', :name => category_name, :single_value => single_value, :description => "#{category_description}")
    end
    # if the tag exists else create it
    unless $evm.execute('tag_exists?', category_name, tag_name)
      log(:info, "Adding new tag <#{tag_name}> description <#{tag_description}> in Category <#{category_name}>")
      $evm.execute('tag_create', category_name, :name => tag_name, :description => "#{tag_description}")
    end
  end

  def run_linux_admin(cmd)
    require 'linux_admin'
    log(:info, "Executing command: #{cmd}")
    begin
      result = LinuxAdmin.run!(cmd)
      log(:info, "Inspecting output: #{result.output.inspect}")
      log(:info, "Inspecting error: #{result.error.inspect}")
      log(:info, "Inspecting exit_status: #{result.exit_status.inspect}")
      return result
    rescue => admincmderr
      log(:error, "Error running #{cmd}: #{admincmderr}")
      log(:error, "Backtrace: #{admincmderr.backtrace.join('\n')}")
      return false
    end
  end

  def process_runlist(vm)
    non_zeroconf_ipaddr = nil
    vm.ipaddresses.each do |ipaddr|
      unless ipaddr.match(/^(169.254|0)/)
	non_zeroconf_ipaddr = ipaddr
	break
      end
    end

    log(:info, "Getting runlist for IP #{non_zeroconf_ipaddr}")
    cmd = "/var/www/miq/knife_wrapper.sh status --run-list 'addresses:#{non_zeroconf_ipaddr}'"
    results = run_linux_admin(cmd)
    if results.exit_status.zero?
      log(:info, "OUTPUT: #{results.output.to_s}")
      if results.output.to_s.blank?
        log(:info, "Output of knife status is blank, doing a retry on this")
        retry_method
      end
      items = results.output.to_s.split(", ")
      log(:info, "Split Up: #{items.inspect}")
      vm.custom_set("CHEF_Last_Checkin", "#{items[0]}")
      recipes = ""
      for item in items
        if item.match(/^\[.*\]/)
	  matches = item.match(/^\[(.*)\]/)
	  recipes = matches[1]
        end
      end
      vm.custom_set("CHEF_Recipes", recipes) unless recipes.blank?
    else
      log(:error, "Command #{cmd} failed #{results.error.inspect}")
      exit MIQ_STOP
    end
  end

  def get_os_type(vm)
    if vm.vendor == "OpenStack"
      # OpenStack providers do not give us an OS product name, so we
      # have to guess the OS based on the image name.

      template_name = $evm.root['miq_provision'].vm_template.name
      if template_name =~ /(rhel|redhat)/i
        return "linux"
      elsif template_name =~ /WIN/
        return "windows"
      elsif template_name =~ /windows/i
        return "windows"
      else
        error("Cannot determine OS from template name #{template_name}")
      end
    else
      # With VMware and RHEV, we can use the OS product name.

      product_name = vm.operating_system.product_name
      if product_name =~ /(rhel|linux)/i
        return "linux"
      elsif product_name =~ /windows/i
        return "windows"
      else
        error("Unknown OS product #{product_name}")
      end
    end
  end

  log(:info, "CFME Automate Method Started")

  # dump all root attributes to the log
  dump_root

  vm = nil

  case $evm.root['vmdb_object_type']
    when 'miq_provision'
      log(:info, "Getting VM from MIQ Provision Object")

      prov = $evm.root['miq_provision']

      vm = prov.vm
      log(:info, "Got VM #{vm.name} from miq_provision")
    when 'vm'
      log(:info, "Getting vm from $evm.root['vm']")
      vm = $evm.root['vm']
      log(:info, "Got #{vm.name} from $evm.root['vm']")
  end

  process_tags("chef_status", "Chef Status", true, "active", "Active")
  vm.tag_assign("chef_status/active")

  process_runlist(vm)

  # Exit method
  log(:info, "CFME Automate Method Ended")
  exit MIQ_OK

  # Ruby rescue
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
