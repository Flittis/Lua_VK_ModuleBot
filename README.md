# Lua_VK_ModuleBot


## **First, you must to install last versions of _[LUAJIT](https://luajit.org)_ and _[LuaRocks](https://luarocks.org/)_**

- **If you have, delete old Lua5.3 and LuaRocks**
```
-$ rm -rf /var/cache/luarocks /usr/local/include/lua.hpp /usr/local/include/lua.h /usr/local/etc/luarocks /usr/local/bin/luarocks-admin /usr/local/bin/luarocks /usr/local/bin/lua /usr/local/lib/luarocks /usr/local/lib/lua/5.3 /usr/local/share/lua
```

- **Install development tools:**
```
 -$ sudo apt install build-essential libreadline-dev
```

- **Install _LUA_:**
```
-$ git clone https://luajit.org/git/luajit-2.0.git
-$ cd luajit-2.0
-$ git checkout v2.1
-$ sudo make install
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
-$ git checkout jit-version
```

- **Open folder, which you cloned, and install packages:**
```
-$ luarocks install luautf8
-$ luarocks install dkjson
```

## Settings

- **Follow the link:**
https://vk.cc/8E0H4r

- **Copy access token from adress line.**
![alt text](https://github.com/Flittis/Lua_VK_ModuleBot/raw/master/tokenScreen.jpg)

- **And then put your token in quotes beside accessToken in _config.lua_**
```
accessToken = " token here "
```
