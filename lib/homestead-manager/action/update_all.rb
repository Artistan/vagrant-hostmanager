require 'homestead-manager/hosts_file/updater'
require 'homestead-manager/util'

module VagrantPlugins
  module HomesteadManager
    module Action
      class UpdateAll

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @global_env = @machine.env
          @provider = @machine.provider_name
          @config = Util.get_config(@global_env)
          @updater = HostsFile::Updater.new(@global_env, @provider)
          @logger = Log4r::Logger.new('vagrant::hsmanager::update_all')
        end

        def call(env)
          # skip if machine is not active on destroy action
          return @app.call(env) if !@machine.id && env[:machine_action] == :destroy

          # check config to see if the hosts file should be update automatically
          return @app.call(env) unless @config.hsmanager.enabled?
          @logger.info 'Updating /etc/hosts file automatically'

          @app.call(env)

          # update /etc/hosts file on active machines
          if @machine.config.hsmanager.manage_guest?
            env[:ui].info I18n.t('homestead_manager.action.update_guests')
            @global_env.active_machines.each do |name, p|
              if p == @provider
                machine = @global_env.machine(name, p)
                state = machine.state
                if ['active','running'].include?(state.short_description)
                  @updater.update_guest(machine)
                end
              end
            end
          end

          # update /etc/hosts files on host if enabled
          if @machine.config.hsmanager.manage_host?
            env[:ui].info I18n.t('homestead_manager.action.update_host')
            @updater.update_host
          end
        end
      end
    end
  end
end
