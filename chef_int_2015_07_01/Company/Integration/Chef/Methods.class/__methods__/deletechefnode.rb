###################################
#
# CFME Automate Method: chef_delete
#
# Notes: This method uses a kinfe wrapper to bootstrap a Chef client
#
###################################
begin
  # Method for logging
  def log(level, message)
    @method = 'chef_delete'
    $evm.log(level, "#{@method}: #{message}")
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
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

  # If the VM was registered in Chef, unregister it.
  if vm.custom_get('CHEF_Bootstrapped')
    nodename = vm.custom_get('CHEF_nodename')
    if nodename
      cmd = "/var/www/miq/knife_wrapper.sh node delete #{nodename} -y"
      run_linux_admin(cmd)
      vm.custom_set("CHEF_Bootstrapped", nil)
      vm.custom_set("CHEF_Last_Checkin", nil)
      vm.custom_set("CHEF_Roles", nil)
      vm.custom_set("CHEF_Recipes", nil)
      process_tags("chef_status", "Chef Status", true, "inactive", "Inactive")
      vm.tag_assign("chef_status/inactive")
    else
      log(:info, "No CHEF_nodename attribute, skipping Chef deletion")
    end
  end

  # Exit method
  log(:info, "CFME Automate Method Ended")
  exit MIQ_OK

  # Ruby rescue
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
