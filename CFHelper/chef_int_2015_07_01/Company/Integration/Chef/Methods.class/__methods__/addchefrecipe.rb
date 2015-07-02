###################################
#
# CFME Automate Method: AddChefRecipe
#
# Notes: This method uses a kinfe wrapper to bootstrap a Chef client
#
###################################
begin
  # Method for logging
  def log(level, message)
    @method = 'AddChefRecipe'
    $evm.log(level, "#{@method}: #{message}")
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
  end

  def dump_vm(vm)
    log(:info, "VM:<#{vm.name}> Begin Attributes [vm.attributes]")
    vm.attributes.sort.each { |k, v| log(:info, "VM:<#{vm.name}> Attributes - #{k}: #{v.inspect}")}
    log(:info, "VM:<#{vm.name}> End Attributes [vm.attributes]")
    log(:info, "")
  end

  # basic retry logic
  def retry_method(retry_time=1.minute)
    log(:info, "Sleeping for #{retry_time} seconds")
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = retry_time
    exit MIQ_OK
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

  def add_chef_recipe(vm, chef_recipe)
    os_type = get_os_type(vm)
    nodename = vm.custom_get('CHEF_nodename')

    log(:info,"Adding recipe '#{chef_recipe}' to '#{nodename}'")
    cmd = "/var/www/miq/knife_wrapper.sh node run_list add #{nodename} " +
          "recipe[#{chef_recipe}]"
    result = run_linux_admin(cmd)
    if result.exit_status.zero?
      log(:info, "Added chef recipe #{chef_recipe} successfully")
    else
      log(:error, "Error adding chef recipe #{chef_recipe}")
      raise "Error adding chef role #{chef_recipe}"
    end
  end

  log(:info, "CFME Automate Method Started")

  # dump all root attributes to the log
  dump_root

  prov = $evm.root['miq_provision']
  vm = prov.vm

  ws_values = prov.get_option(:ws_values) || {}  

  cookbook = ws_values[:chef_cookbook]
  cookbook = cookbook.split(" ")[0] if cookbook

  unless cookbook.blank?
    add_chef_recipe(vm, cookbook)
  else
    log(:info, "No chef recipe specified, ignoring")
  end

  # Exit method
  log(:info, "CFME Automate Method Ended")
  exit MIQ_OK

  # Ruby rescue
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
