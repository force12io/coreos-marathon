Bundler.require

require 'open-uri'
require 'yaml'
require 'uri'

# Simple client for the Packet.net REST API. Creates and destroys a cluster
# of 3 physical servers running Marathon.
class PacketApi
  DISCOVERY_TOKEN_ENDPOINT = 'https://discovery.etcd.io/new?size=3'
  PACKET_API_HOST = 'api.packet.net'
  ACCEPT_HEADER = 'application/json; version=1'

  # Creates a Marathon cluster. Called from packet:cluster:create Rake task.
  def create_cluster
    project_id = create_project(ENV['PROJECT_NAME'])

    # Get fresh discovery token each time
    token = get_discovery_token

    create_device(project_id, '01', 'master', token)
    create_device(project_id, '02', 'slave', token)
    create_device(project_id, '03', 'slave', token)
  end

  # Destroys a Marathon cluster. Called from packet:cluster:destroy Rake task.
  def destroy_cluster
    project_id = get_project_id(ENV['PROJECT_NAME'])
    device_ids = list_devices(project_id)

    device_ids.each do |device_id|
      destroy_device(project_id, device_id)
    end

    destroy_project(project_id)
  end

private
  # Create a Packet project which is a collection of servers.
  def create_project(project_name)
    project_id = get_project_id(project_name)

    if project_id == nil
      request = { 'name' => project_name }

      data = call_api(:post, get_project_url, request.to_json)
      project_id = data['id']
    end

    project_id
  end

  # Get the Packet project id.
  def get_project_id(project_name)
    project_id = nil
    data = call_api(:get, get_project_url)

    data['projects'].each do |project|
      project_id = project['id'] if project['name'] == project_name
    end

    project_id
  end

  # Delete a Packet project.
  def destroy_project(project_id)
    project_uri = get_project_url(project_id)
    call_api(:delete, project_uri.to_s)
  end

  # List the devices in a Packet project.
  def list_devices(project_id)
    device_ids = []
    data = call_api(:get, get_device_url(project_id))

    data['devices'].each do |device|
      device_ids.push(device['id'])
    end

    device_ids
  end

  # Provision a physical server.
  def create_device(project_id, device_num, role, token)
    hostname = [ENV['DEVICE_PREFIX'] + '-' + device_num, ENV['DEVICE_DOMAIN']].join('.')

    device_config = {
      'hostname' => hostname,
      'plan' => ENV['PLAN'],
      'facility' => ENV['FACILITY'],
      'operating_system' => ENV['OPERATING_SYSTEM'],
      'userdata' => set_discovery_token(role, token)
    }

    call_api(:post, get_device_url(project_id), device_config.to_json)
  end

  # Delete a physical server.
  def destroy_device(project_id, device_id)
    device_url = get_device_url(project_id, device_id)
    call_api(:delete, device_url)
  end

  # Get a new discovery token from discovery.etcd.io.
  def get_discovery_token
    open(DISCOVERY_TOKEN_ENDPOINT).read
  end

  # Sets a new discovery token and sets the #cloud-config comment that
  # must be the first line.
  def set_discovery_token(role, token)
    user_data = role + '-user-data'

    data = YAML.load(IO.readlines(user_data)[1..-1].join)
    data['coreos']['etcd2']['discovery'] = token

    "#cloud-config\n\n#{YAML.dump(data)}"
  end

  # Create a project url with optional project id.
  def get_project_url(project_id = '')
    path = ['/projects/', project_id].join
    uri = URI::HTTPS.build(:host => PACKET_API_HOST, :path => path)

    uri.to_s
  end

  # Create a device url with project id and optional device id.
  def get_device_url(project_id, device_id = '')
    path = ['/projects/', project_id, '/devices/', device_id].join
    uri = URI::HTTPS.build(:host => PACKET_API_HOST, :path => path)

    uri.to_s
  end

  # Helper method for adding API call headers.
  def call_api(method, url, payload = nil)
    data = nil

    begin
      headers = {
        :accept => ACCEPT_HEADER,
        :content_type => :json,
        'X-Auth-Token' => ENV['API_TOKEN']
      }

      response = RestClient::Request.execute(:method => method,
                                             :headers => headers,
                                             :url => url,
                                             :payload => payload)
      data = JSON.parse(response.body) if response.code == 200 || response.code == 201

    rescue RestClient::Exception => re
      puts ['ERROR:', method.to_s.upcase, url].join(' ')
      puts re.inspect

      # Re raise exception to prevent further api calls.
      raise re
    end

    data
  end
end
