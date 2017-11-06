
nginx.conf
```
    lua_code_cache on;
    lua_package_path "/opt/lua/?.lua;;";

    lua_shared_dict lb_opt_cache 20m;
    lua_shared_dict cache_locks 1m;

    lua_shared_dict lb_req_store 100m;
    lua_shared_dict lb_conn_store 100m;
```
