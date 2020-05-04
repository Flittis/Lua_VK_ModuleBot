# Lua_VK_ModuleBot

# **This version is deprecated**
- **Please us new ModuleBot with LuaJit**
- https://github.com/Flittis/Lua_VK_ModuleBot/tree/jit-version
- https://github.com/Flittis/Lua_VK_ModuleBot/tree/jit-version
- https://github.com/Flittis/Lua_VK_ModuleBot/tree/jit-version



## **First, you must to install last versions of _[LUA](https://www.lua.org)_ and _[LuaRocks](https://luarocks.org/)_**
- **Install development tools:**
```
 -$ sudo apt install build-essential libreadline-dev
```

- **Install _LUA_:**
```
-$ curl -R -O http://www.lua.org/ftp/lua-5.3.4.tar.gz
-$ tar -zxf lua-5.3.4.tar.gz
-$ cd lua-5.3.4
-$ make linux test
-$ sudo make install
```
- **Install _LuaRocks_:**
```
-$ wget https://luarocks.org/releases/luarocks-3.3.1.tar.gz
-$ tar zxpf luarocks-3.3.1.tar.gz
-$ cd luarocks-3.3.1
-$ ./configure
-$ make build
-$ make install
```

- **When installed, clone this repository**
```
-$ git clone https://github.com/Flittis/Lua_VK_ModuleBot.git
```

- **Open folder, which you cloned, and install packages:**
```
-$ luarocks install luautf8
-$ luarocks install dkjson
-$ luarocks install Lua-cURL
-$ luarocks install luafilesystem
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
