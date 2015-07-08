require 'dotenv/tasks'

require_relative 'packet_api'

namespace :packet do
  namespace :cluster do
    desc "Create cluster of 3 physical servers running Marathon"
    task :create => :dotenv do |task|
      api = PacketApi.new
      api.create_cluster

      puts "\nCluster is being provisioned"
    end

    desc "Shutdown server cluster"
    task :destroy => :dotenv do |task|
      api = PacketApi.new
      api.destroy_cluster

      puts "\nCluster has been shutdown"
    end
  end
end
