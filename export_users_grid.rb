require 'json'
require 'httpclient'
require 'open-uri'

# constants
$my_base_url            = "https://rally1.rallydev.com/slm"
$my_username            = "subadmin@company.com"
$my_password            = "password"
$my_headers             = $headers
$my_page_size           = 200
$my_limit               = 50000
$my_wsapi_version       = "v2.0"

$my_workspace_oid       = 12345678910
$my_project_oid         = 12345678911

$my_fetch_arr           = ["gridra","UserName","DisplayName","Permission",
                           "CreationDate","EmailAddress","Disabled","MiddleName",
                           "LastPasswordUpdateDate","LastLoginDate","NetworkID"]
$my_types_arr           = ["SubscriptionUser","WorkspaceUser"]


$project_admin_query    = '(Permission = "Project Admin")'
$workspace_admin_query  = '(Permission = "Workspace Admin")'
$enabled_query          = "(Disabled = false)"
$my_query               = "(#{$enabled_query} AND #{$project_admin_query})"
$my_order               = "UserName,ObjectID ASC,ASC"

if $my_delim == nil then $my_delim = "," end

def initialize_rally

    @rally_url                          = $my_base_url
    @rally_user                         = $my_username
    @rally_password                     = $my_password
    @login_succeeded_loc                = "#{@rally_url}/slm/"
    @login_failed_loc                   = "#{@rally_url}/slm/loginFailed.op"
    @security_token                     = ""
    @wsapi_version                      = $my_wsapi_version

    @rally                              = HTTPClient.new

    default_timeout = 300
    @rally.connect_timeout              = default_timeout
    @rally.send_timeout                 = default_timeout
    @rally.receive_timeout              = default_timeout
    @rally.keep_alive_timeout           = default_timeout
end

def make_auth_url
    return "#{@rally_url}/webservice/#{@wsapi_version}/security/authorize"
end

def authorize

    auth_successful = false

    auth_url = make_auth_url
    @rally.set_auth(@rally_url, @rally_user, @rally_password)
    @rally.www_auth.basic_auth.challenge(@rally_url)

    method = :get
    req_args = {}
    req_headers = {}
    req_headers["Content-Type"] = "application/json"
    req_headers["Accept"] = "application/json"

    req_args[:header] = req_headers
    auth_response = @rally.request(method, auth_url, req_args)
    auth_json = JSON.parse(auth_response.body)
    @security_token = auth_json["OperationResult"]["SecurityToken"]
    if !@security_token.nil? then
        auth_successful = true
    end
    return auth_successful
end

def make_user_grid_url

    base_grid_url = "#{@rally_url}/webservice/x/users/grid.csv"
    fetch = URI::encode($my_fetch_arr.join(","))
    order = URI::encode($my_order)
    query = URI::encode($my_query)
    workspaceScope = $my_workspace_oid.to_s
    projectRef = "/project/#{$my_project_oid.to_s}"
    types = URI::encode($my_types_arr.join(","))

    user_grid_url = "#{base_grid_url}?workspaceScope=#{workspaceScope}&fetch=#{fetch}&query=#{query}&order=#{order}&project=#{projectRef}&types=#{types}"

end

def make_usage_filename
    timestamp = DateTime.now()
    timestamp_string = timestamp.strftime("%Y%m%d%H%M%S")
    return "usersgrid_export_#{timestamp_string}.csv"
end

def get_users_grid_csv

    users_grid_url = make_user_grid_url
    users_csv_filename = make_usage_filename

    method = :get
    req_headers = {}
    req_args = {}

    # Including the following in request headers will cause returned output to be compressed
    # req_headers['Accept-Encoding'] = 'gzip,deflate,sdch'

    req_headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    req_headers['Connection'] = 'keep-alive'
    req_args[:header] = req_headers

    begin
        users_grid_response = @rally.request(method, users_grid_url, req_args)
    rescue => ex
        raise ex
    end

    begin
        users_grid_csv = File.open(users_csv_filename, "wb")
        users_grid_csv.write(users_grid_response.body)
        file_basename = users_grid_csv.path.split("/")[-1]
        return file_basename

    rescue IOError => ex
        #some error occur, dir not writable etc.
        puts "Error occurred writing file: "
        puts ex.message
        puts ex.backtrace
    ensure
        users_grid_csv.close unless users_grid_csv == nil
    end
end

begin

    # Load (and maybe override with) my personal/private variables from a file...
    my_vars= File.dirname(__FILE__) + "/my_vars_users_grid.rb"
    if FileTest.exist?( my_vars ) then require my_vars end

    initialize_rally
    is_authorized = authorize

    if is_authorized then
        puts "Authentication to Rally successful..."
    else
        puts "Error authenticating to Rally... Exiting."
        exit
    end

    users_grid_filename = get_users_grid_csv
    puts "Export of Users Grid saved to #{users_grid_filename}."
    puts "Done!"

end