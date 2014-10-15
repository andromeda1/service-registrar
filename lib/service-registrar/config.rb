#
#   Author: Rohith
#   Date: 2014-10-10 20:53:17 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'yaml'

module ServiceRegistrar
  module Configuration
    def default_configuration
      {
        'docker'       => '/var/run/docker.sock',
        'daemonize'    => false,
        'interval'     => 5000,
        'ttl'          => 12000,
        'log'          => STDOUT,
        'loglevel'     => 'info',
        'stats_prefix' => 'registrar-service',
        'path'     => [
          "string:services",
          "environment:ENVIRONMENT",
          "environment:APP",
          "environment:NAME",
          "container:HOSTNAME",
        ],
        'backend'  => 'etcd',
        'backends' => {
          'zookeeper' => {
            'uri'   => 'zk://localhost:2181',
            'path'  => '/services',
          },
          'etcd' => {
            'host'  => 'localhost',
            'port'  => 49153
          }
        }
      }.dup
    end

    def settings
      @configuration ||= {}
    end

    private
    def validate_configuration config
      # step: start by loading the default configuration
      @configuration = default_configuration
      # step: load the configuration file if we have one
      @configuration.merge!(load_configuration config['config'])
      # step: merge the user defined options
      @configuration.merge!(config)
      # step: setup the logger
      Logging::Logger::init @configuration['log'], loglevel( @configuration['loglevel'] )
      # checkpoint: we should have a fully merged config now
      debug "validate_configuration: merged configuration: #{@configuration}"
      # step: verfiy the config is correct
      required_settings %w(docker interval ttl log loglevel backend backends), @configuration
      # step: check the actual config
      raise ArgumentError, "interval should be a positive integer" unless postive_integer? @configuration['interval']
      raise ArgumentError, "ttl should be positive integer"        unless postive_integer? @configuration['ttl']
      # step: check the backend configuration
      validate_backend @configuration
      # step: check the docker socket
      validate_docker @configuration
      # step: return the configuration
      @configuration
    end

    def validate_backend configuration
      debug "validate_backend_configuration: checking the backend configuration"
      backend = configuration['backend']
      info "validate_backend_configuration: backend selected: #{backend}"
      info "validate_backend_configuration: available backends: #{backends}"
      backend_config = configuration['backends'][backend] || {}
      # check the backend exists
      unless backends.include? backend
        raise ArgumentError, "invalid backend, available backends are #{backends.join(',')}"
      end
      unless configuration['backends'].has_key? backend
        raise ArgumentError, "you have not specified any backend configuration"
      end
      # step: check the backend config
      debug "validate_backend_configuration: checking the configuration against the backend: #{backend}"
      backend_configuration backend, backend_config
      info "validate_backend_configuration: backend configuration correct"
    end

    def validate_docker config
      socket = config['docker']
      raise ArgumentError, "the docker socket: #{socket} does not exist"    unless File.exists? socket
      raise ArgumentError, "the docker socket: #{socket} is not a socket"   unless File.socket? socket
      raise ArgumentError, "the docker socket: #{socket} is not readable"   unless File.readable? socket
      raise ArgumentError, "the docker socket: #{socket} is not writable"  unless File.writable? socket
    end

    def load_configuration filename
      ( filename ) ? ::YAML.load(File.read(filename)) : {}
    end
  end
end