###################################
#
# CFME Automate Method: Chef_Bootstrap
#
# Notes: This method uses a kinfe wrapper to bootstrap a Chef client
#
###################################

# Method for logging
def log(level, message)
  @method = 'BootstrapVM'
  $evm.log(level, "#{@method}: #{message}")
end

def error(msg)
  log(:error, "#{msg}")
  $evm.root['ae_result'] = 'error'
  $evm.root['ae_reason'] = msg
  exit MIQ_OK
end

begin
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

  def verify_bootstrapped(nodename)
    nodename = nodename.downcase
    log(:info, "Finding #{nodename} in chef node list")
    cmd = "/var/www/miq/knife_wrapper.sh node list"
    result = run_linux_admin(cmd)
    if result.exit_status.zero?
      hosts = result.output.split("\n")
      for host in hosts
        if host == nodename
          log(:info, "Found #{host} in knife node list")
          return true
        end
      end
      log(:info, "Did not find #{nodename} in #{hosts.inspect}")
      return false
    else
      log(:error, "Error running #{cmd}, failing")
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

  def chef_bootstrap(vm, ipaddr, nodename)
    os_type = get_os_type(vm)
    cmd = nil
    if os_type == "linux"
      username = $evm.object['linuxUsername']
      password = $evm.object.decrypt('linuxPassword')
      cmd = "/var/www/miq/knife_wrapper.sh bootstrap #{ipaddr} -N #{nodename} -x '#{username}' -P '#{password}' --node-ssl-verify-mode none --no-host-key-verify >&/tmp/chef-bootstrap.log"
    elsif os_type == "windows"
      username = $evm.object['windowsUsername']
      password = $evm.object.decrypt('windowsPassword')
      cmd = "/var/www/miq/knife_wrapper.sh bootstrap windows winrm #{ipaddr} -N #{nodename} -x '#{username}' -P '#{password}' --node-ssl-verify-mode none >&/tmp/chef-bootstrap.log"
    else
      error("Unknown os_type #{os_type}")
    end
    
    result = run_linux_admin(cmd)
    if result
      if result.exit_status.zero?
	log(:info, "Successfully bootstrapped #{ipaddr}")
	return true
      else
	error("Error bootstrapping #{ipaddr}: #{result.error.inspect}")
      end
    else
      error("Error bootstrapping #{ipaddr}")
    end
    return false
  end

  log(:info, "CFME Automate Method Started")

  # dump all root attributes to the log
  dump_root

  log(:info, "Getting VM from MIQ Provision Object")

  prov = $evm.root['miq_provision']

  vm = prov.vm
  log(:info, "Got VM #{vm.name} from miq_provision")

  ws_values = prov.options.fetch(:ws_values, nil)
  domain_name = ws_values[:domain_name]

  # raise an exception if the VM object is nil
  raise "VM Object is nil, cannot bootstrap nil" if vm.nil?

  log(:info, "EVM Object: #{$evm.object.inspect}")

  # Since this may support provisioning we need to put in retry logic to wait
  # until IP Addresses are populated.
  non_zeroconf_ipaddr = nil
  vm.ipaddresses.each do |ipaddr|
    unless ipaddr.match(/^(169.254|0)/)
      non_zeroconf_ipaddr = ipaddr
      break
    end
  end
  if non_zeroconf_ipaddr
    log(:info, "VM:<#{vm.name}> IP addresses:<#{vm.ipaddresses.inspect}> present.")
    $evm.root['ae_result'] = 'ok'
  else
    log(:warn, "VM:<#{vm.name}> IP addresses:<#{vm.ipaddresses.inspect}> not present.")

    # Update the VMDB to include the assigned IP address.
    vm.refresh

    retry_method("1.minute")
  end

  nodename = "#{vm.name}.#{domain_name}"

  bootstrapped = verify_bootstrapped(nodename)
  bootstrapped = chef_bootstrap(vm, non_zeroconf_ipaddr, nodename) unless bootstrapped
  if bootstrapped
    log(:info, "Successfully bootstrapped #{nodename}")
    obj = $evm.object
    obj['status'] = "active"
    if vm.custom_get("CHEF_Bootstrapped").nil?
      vm.custom_set("CHEF_Bootstrapped", "YES: #{Time.now}")
    end
    vm.custom_set('CHEF_nodename', nodename)
  else
    obj['status'] = "inactive"
    log(:error, "Unable to bootstrap #{nodename} #{vm.ipaddresses.first}")
    exit MIQ_ABORT
  end

  obj['vm'] = vm

  # Exit method
  log(:info, "CFME Automate Method Ended")
  exit MIQ_OK

  # Ruby rescue
rescue => err
  error("[#{err}]\n#{err.backtrace.join("\n")}")
end
