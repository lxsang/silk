
-- the rewrite rule for the framework
-- should be something like this
-- ^\/apps\/+(.*)$ = /apps/router.lua?r=<1>&<query>
-- some global variables
DIR_SEP = "/"
WWW_ROOT = "/opt/www/htdocs/apps"
HTTP_ROOT = "https://apps.localhost:9195/"
-- class path: path.to.class
BASE_FRW = ""
-- class path: path.to.class
CONTROLLER_ROOT = BASE_FRW.."apps.controllers"
MODEL_ROOT = BASE_FRW.."apps.models"
-- file path: path/to/file
VIEW_ROOT = WWW_ROOT..DIR_SEP.."views"
LOG_ROOT = WWW_ROOT..DIR_SEP.."logs"

-- require needed library
require(BASE_FRW.."silk.api")

-- registry object store global variables
local REGISTRY = {}
-- set logging level
REGISTRY.logger = Logger:new{ levels = {INFO = true, ERROR = true, DEBUG = true}}
REGISTRY.db = DBHelper:new{db="iosapps"}
REGISTRY.layout = 'default'

REGISTRY.db:open()
local router = Router:new{registry = REGISTRY}
REGISTRY.router = router
router:setPath(CONTROLLER_ROOT)
--router:route('edit', 'post/edit', "ALL" )

-- example of depedencies to the current main route
-- each layout may have different dependencies
local default_routes_dependencies = {
    edit = {
        url = "post/edit",
        visibility = {
            shown = true,
            routes = {
                ["post/index"] = true
            }
        }
    },
    --category = {
    --    url = "cat/index",
    --    visibility = "ALL"
    --}
}
router:route('default', default_routes_dependencies )
router:delegate()
if REGISTRY.db then REGISTRY.db:close() end

