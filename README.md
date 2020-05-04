# Lua_VK_ModuleBot


## **First, you must to install last versions of _[LUAJIT](https://luajit.org)_ and _[LuaRocks](https://luarocks.org/)_**

- **If you have, delete old Lua5.3 and LuaRocks**
```
-$ rm -rf /var/cache/luarocks /usr/local/include/lua.hpp /usr/local/include/lua.h /usr/local/etc/luarocks /usr/local/bin/luarocks-admin /usr/local/bin/luarocks /usr/local/bin/lua /usr/local/lib/luarocks /usr/local/lib/lua/5.3 /usr/local/share/lua
```

- **Install development tools:**
```
 -$ sudo apt install build-essential libreadline-dev libcurl4-openssl-dev
 -$ sudo ln -s /usr/include/x86_64-linux-gnu/curl /usr/include/curl
```

- **Install _LUAJIT_:**
```
-$ git clone https://luajit.org/git/luajit-2.0.git
-$ cd luajit-2.0
-$ git checkout v2.1
-$ sudo make install
-$ ln -sf luajit-2.1.0-beta3 /usr/local/bin/luajit
```
- **Install _LuaRocks_:**
```
-$ wget https://luarocks.org/releases/luarocks-3.3.1.tar.gz
-$ tar zxpf luarocks-3.3.1.tar.gz
-$ cd luarocks-3.3.1
-$ ./configure
-$ make build
-$ sudo make install
```

- **When installed, clone this repository**
```
-$ git clone https://github.com/Flittis/Lua_VK_ModuleBot.git
-$ cd Lua_VK_ModuleBot
```

- **Install packages:**
```
-$ luarocks install luautf8
-$ luarocks install dkjson
```

## Starting

- **Start script to create config file**
```
-$ luajit index.lua    --> [ERROR] Access token in config is not defined
```
This will create _config.lua_ file

## Get token

- **Follow the link:**
https://vk.cc/8E0H4r

- **Copy access token from adress line.**
![alt text](https://github.com/Flittis/Lua_VK_ModuleBot/raw/master/tokenScreen.jpg)

- **And then put your token in quotes beside accessToken in _config.lua_**
```
accessToken = " token here "
```
