# constants
$my_base_url            = "https://rally1.rallydev.com/slm"
$my_username            = "subadmin@company.com"
$my_password            = "topsecret"
$my_headers             = $headers
$my_page_size           = 200
$my_limit               = 50000
$my_wsapi_version       = "v2.0"

$my_workspace_oid       = 12345678910
$my_project_oid         = 12345678911

$my_fetch_arr              = ["gridra","UserName","DisplayName","Permission",
                           "CreationDate","EmailAddress","Disabled","MiddleName",
                           "LastPasswordUpdateDate","LastLoginDate","NetworkID"]

$project_admin_query    = '(Permission = "Project Admin")'
$workspace_admin_query  = '(Permission = "Workspace Admin")'
$enabled_query          = "(Disabled = false)"
$my_query               = "(#{$enabled_query} AND #{$project_admin_query})"
$my_order               = "UserName,ObjectID ASC,ASC"
$my_types_arr           = ["SubscriptionUser","WorkspaceUser"]