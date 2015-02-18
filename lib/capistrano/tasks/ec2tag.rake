require 'aws-sdk'

namespace :ec2tag do


  task :tag, :which do |t, args|

    client = Aws::EC2::Client.new(region: fetch(:aws_region, 'us-east-1'))
    resource = Aws::EC2::Resource.new(client: client)

    server_list = []
    if set_to = args.extras.last.delete(:set_to)
      server_list = fetch(set_to, server_list)
    end

    servers =resource.instances(filters:[{name:'instance-state-name', values:['running']},
                                          {name:'tag-key',values:[fetch(:ec2_deploy_tag, 'deploy')]},
                                          {name:'tag-value', values:[args[:which]]}
                                 ])

    servers.map do |instance|
      name_tag=instance.tags.select{|tag| tag.key=="Name"}
      name= name_tag.first.value if (name_tag && !name_tag.empty?)
      server_list << name || instance.ip_address
      server instance.public_ip_address || instance.private_ip_address, *args.extras
    end
    unless set_to.nil?
      set set_to, server_list.uniq
    end

    ::Rake.application['ec2tag:tag'].reenable
  end

end
