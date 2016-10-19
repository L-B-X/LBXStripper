-- @version 0.90
-- @author lbx
-- @changelog

--[[
   * ReaScript Name: LBX Stripper
   * Lua script for Cockos REAPER
   * Author: Leon Bradley (LBX)
   * Author URI: 
   * Licence: GPL v3
  ]]
    
  --------------------------------------------
        
  submode_table = {'FX PARAMS','GRAPHICS','STRIPS'}
  ctltype_table = {'KNOB/SLIDER','BUTTON','BUTTON INV','CYCLE BUTTON','METER'}

  ---------------------------------------------
  -- Pickle.lua
  -- A table serialization utility for lua
  -- Steve Dekorte, http://www.dekorte.com, Apr 2000
  -- (updated for Lua 5.3 by me)
  -- Freeware
  ----------------------------------------------
  
  function pickle(t)
  return Pickle:clone():pickle_(t)
  end
  
  Pickle = {
  clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end
  }
  
  function Pickle:pickle_(root)
  if type(root) ~= "table" then
  error("can only pickle tables, not ".. type(root).."s")
  end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  
  while #self._refToTable > savecount do
  savecount = savecount + 1
  local t = self._refToTable[savecount]
  s = s.."{\n"
  
  for i, v in pairs(t) do
  s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
  end
  s = s.."},\n"
  end
  
  return string.format("{%s}", s)
  end
  
  function Pickle:value_(v)
  local vtype = type(v)
  if vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a "..type(v).." is not supported")
  end
  end
  
  function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then
  if t == self then error("can't pickle the pickle class") end
  table.insert(self._refToTable, t)
  ref = #self._refToTable
  self._tableToRef[t] = ref
  end
  return ref
  end
  
  ----------------------------------------------
  -- unpickle
  ----------------------------------------------
  
  function unpickle(s)
  if type(s) ~= "string" then
  error("can't unpickle a "..type(s)..", only strings")
  end
  local gentables = load("return "..s)
  local tables = gentables()
  
  for tnum = 1, #tables do
  local t = tables[tnum]
  local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
  for i, v in pairs(tcopy) do
  local ni, nv
  if type(i) == "table" then ni = tables[i[1]] else ni = i end
  if type(v) == "table" then nv = tables[v[1]] else nv = v end
  t[i] = nil
  t[ni] = nv
  end
  end
  return tables[1]
  end
        
  ------------------------------------------------------------
  
  function DBG(str)
  if str==nil then str="nil" end
  reaper.ShowConsoleMsg(tostring(str).."\n")
  end
  
  ------------------------------------------------------------
  
  function tobool(b)
  
    local ret
    if tostring(b) == "true" then
      ret = true
    else
      ret = false
    end
    return ret
    
  end
  
  function convertguid(g)
    return string.match(g,'{(.*)}')
  end
  
  val_to_dB = function(val) return 20*math.log(val, 10) end
  dB_to_val = function(dB_val) return 10^(dB_val/20) end
  
  function GetObjects()
    local obj = {}
      
      obj.sections = {}
      
      local sizex, sizey = 350, 100
      local bsizex, bsizey = 60, 20
      obj.sections[5] = {x = gfx1.main_w/2 - sizex/2 + 25,
                         y = gfx1.main_h/2 - sizey/2 + 10,
                         w = sizex-50, 
                         h = 20}
      obj.sections[6] = {x = gfx1.main_w/2 + sizex/2 - bsizex - 50,
                               y = gfx1.main_h/2 + sizey/2 - bsizey - 10,
                               w = bsizex, 
                               h = bsizey}
      obj.sections[7] = {x = gfx1.main_w/2 + sizex/2 - (bsizex*2) - 60,
                               y = gfx1.main_h/2 + sizey/2 - bsizey - 10,
                               w = bsizex, 
                               h = bsizey}
      obj.sections[8] = {x = gfx1.main_w/2 - sizex/2,
                         y = gfx1.main_h/2 - sizey/2,
                         w = sizex, 
                         h = sizey}
      obj.sections[9] = {x = gfx1.main_w/2 - sizex/2 + 25,
                         y = gfx1.main_h/2 + sizey/2 - 60,
                         w = sizex-50, 
                         h = 20}
      
      --surface
      obj.sections[10] = {x = plist_w+2 + sb_size + 4,
                          y = butt_h+2 + sb_size + 2,
                          w = gfx1.main_w-(plist_w+2+(sb_size+4)*2),
                          h = gfx1.main_h-(butt_h+2+(sb_size+2)*2)}
      if lockx then
        obj.sections[10].x = math.max(obj.sections[10].x, obj.sections[10].x+(obj.sections[10].w/2-lockw/2))
        obj.sections[10].w = math.min(lockw,gfx1.main_w-(plist_w+2+(sb_size+4)*2))
      end
      if locky then
        obj.sections[10].y = math.max(obj.sections[10].y, obj.sections[10].y+(obj.sections[10].h/2-lockh/2))
        obj.sections[10].h = math.min(lockh,gfx1.main_h-(butt_h+2+(sb_size+2)*2))
      end

      --mode
      obj.sections[11] = {x = 0,
                          y = 0,
                          w = plist_w,
                          h = butt_h}
      --track title
      obj.sections[12] = {x = plist_w+2+127,
                          y = 0,
                          w = gfx1.main_w - plist_w - 331,
                          h = butt_h}
      --submode
      obj.sections[13] = {x = 0,
                          y = butt_h+2,
                          w = plist_w,
                          h = butt_h}
      --pages
      obj.sections[14] = {x = gfx1.main_w - 100,
                          y = 0,
                          w = 100,
                          h = butt_h}
      
      obj.sections[15] = {x = 0,
                          y = (butt_h+2)*2,
                          w = plist_w,
                          h = butt_h}
      --save
      obj.sections[17] = {x = gfx1.main_w - 200,
                          y = 0,
                          w = 73,
                          h = butt_h}
      --show/hide sidebar
      obj.sections[18] = {x = plist_w+2,
                          y = 0,
                          w = 25,
                          h = butt_h}
      obj.sections[19] = {x = gfx1.main_w - 125,
                          y = 0,
                          w = 25,
                          h = butt_h}
      --XYUD
      obj.sections[20] = {x = obj.sections[18].x+obj.sections[18].w+2,
                          y = 0,
                          w = 100,
                          h = butt_h}
      obj.sections[21] = {x = gfx1.main_w - 125,
                          y = 0,
                          w = 25,
                          h = butt_h}

      local fx_h = 160
      --FX
      obj.sections[41] = {x = 0,
                          y = butt_h + 2,
                          w = plist_w,
                          h = fx_h+butt_h}
      --PARAMS
      obj.sections[42] = {x = 0,
                          y = obj.sections[41].y + obj.sections[41].h + 10 - butt_h,
                          w = plist_w,
                          h = gfx1.main_h - (obj.sections[41].y + obj.sections[41].h + 10 - butt_h)}
      --TRACKS                    
      obj.sections[43] = {x = 0,
                          y = butt_h+2,
                          w = plist_w,
                          h = gfx1.main_h - (butt_h)}                           
      --GRAPHICS
      obj.sections[44] = {x = 0,
                          y = obj.sections[13].y+obj.sections[13].h+2,
                          w = plist_w,
                          h = gfx1.main_h - (obj.sections[13].y+obj.sections[13].h+2)}                           

      --CONTROL OPTIONS
      obj.sections[45] = {x = gfx1.main_w - plist_w - 20,
                          y = gfx1.main_h - 440 -20,
                          w = plist_w,
                          h = 440}                           
      local sf_h = 140
      --STRIP FOLDERS
      obj.sections[47] = {x = 0,
                          y = obj.sections[15].y+obj.sections[15].h+2,
                          w = plist_w,
                          h = sf_h}                           

      --STRIPS
      obj.sections[46] = {x = 0,
                          y = obj.sections[47].y+obj.sections[47].h+10,
                          w = plist_w,
                          h = gfx1.main_h - (obj.sections[47].y+obj.sections[47].h+10)}                           

      --scale
      obj.sections[50] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+4}                           
      --apply
      obj.sections[51] = {x = obj.sections[45].x+40,
                          y = obj.sections[45].y+150,
                          w = obj.sections[45].w-80,
                          h = butt_h/2+4}                           

      obj.sections[52] = {x = obj.sections[45].x+obj.sections[45].w-40-butt_h/2+4,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10),
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           

      obj.sections[53] = {x = obj.sections[45].x+obj.sections[45].w-40-butt_h/2+4,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 2,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           

      obj.sections[54] = {x = obj.sections[45].x+obj.sections[45].w-40-butt_h/2+4,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 3,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           

      obj.sections[55] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 8,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+8}
      obj.sections[56] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 4,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+4}                           
      obj.sections[57] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 9,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+4}                           

      obj.sections[58] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 6,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+4}                           
      obj.sections[59] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 7,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+8}
      obj.sections[65] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 5,
                          w = obj.sections[45].w-60,
                          h = butt_h/2+4}                           
      obj.sections[66] = {x = obj.sections[45].x+50,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 10,
                          w = obj.sections[45].w-100,
                          h = butt_h/2+4}

      local binh = 45
      obj.sections[60] = {x = plist_w + 10,
                          y = gfx1.main_h - (binh + 10),
                          w = binh,
                          h = binh}
      local msgwinw, msgwinh = 500, 200
      obj.sections[61] = {x = gfx1.main_w/2-msgwinw/2,
                          y = gfx1.main_h/2-msgwinh/2,
                          w = msgwinw,
                          h = msgwinh}
      --ok
      local butt_w = 100
      obj.sections[62] = {x = gfx1.main_w/2-butt_w/2,
                          y = obj.sections[61].y+obj.sections[61].h - butt_h*2,
                          w = butt_w,
                          h = butt_h}                            
      obj.sections[63] = {x = gfx1.main_w/2-msgwinw/2,
                          y = gfx1.main_h/2-msgwinh/2 + butt_h*2,
                          w = msgwinw,
                          h = butt_h}
      --settings
      local setw, seth = 300, 215                            
      obj.sections[70] = {x = gfx1.main_w/2-setw/2,
                          y = gfx1.main_h/2-seth/2,
                          w = setw,
                          h = seth}
      local xofft, yoff, yoffm, bh, bw, sw = 200, 28, butt_h/2+14, butt_h/2+4, butt_h/2+4, 80
      obj.sections[71] = {x = obj.sections[70].x+xofft,
                          y = obj.sections[70].y+yoff + yoffm*0,
                          w = bw,
                          h = bh}
      obj.sections[72] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*1,
                                w = bw,
                                h = bh}
      obj.sections[73] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*2,
                                w = bw,
                                h = bh}
      obj.sections[74] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*3,
                                w = sw,
                                h = bh}
      obj.sections[75] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*4,
                                w = bw,
                                h = bh}
      obj.sections[76] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*5,
                                w = bw,
                                h = bh}
      obj.sections[77] = {x = obj.sections[70].x+xofft+bw+10,
                                y = obj.sections[70].y+yoff + yoffm*4,
                                w = 40,
                                h = bh}
      obj.sections[78] = {x = obj.sections[70].x+xofft+bw+10,
                                y = obj.sections[70].y+yoff + yoffm*5,
                                w = 40,
                                h = bh}
      obj.sections[79] = {x = obj.sections[70].x+xofft+bw+10,
                                y = obj.sections[70].y+yoff + yoffm*6,
                                w = 40,
                                h = bh}
      obj.sections[80] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*6,
                                w = bw,
                                h = bh}
    return obj
  end
  
  -----------------------------------------------------------------------     
  
  function GetGUI_vars()
    gfx.mode = 0
    
    local gui = {}
      gui.aa = 1
      gui.fontname = 'Calibri'
      gui.fontsize_tab = 20    
      gui.fontsz_knob = 18
      if OS == "OSX32" or OS == "OSX64" then gui.fontsize_tab = gui.fontsize_tab - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_knob = gui.fontsz_knob - 5 end
      if OS == "OSX32" or OS == "OSX64" then gui.fontsz_get = gui.fontsz_get - 5 end
      
      gui.color = {['back'] = '71 71 71 ',
                 ['back2'] = '51 63 56',
                 ['black'] = '0 0 0',
                 ['green'] = '102 255 102',
                 ['green1'] = '0 120 169', --'0 156 36',
                 ['green_dark1'] = '0 76 0',
                 ['blue'] = '127 204 255',
                 ['white'] = '205 205 205',
                 ['red'] = '255 0 0',
                 ['green_dark'] = '102 153 102',
                 ['yellow'] = '200 200 0',
                 ['yellow1'] = '160 160 0',
                 ['bryellow'] = '220 220 0',
                 ['cbobg'] = '4 4 4',
                 ['cbobg2'] = '64 64 64',
                 ['grey'] = '0 13 25', --'64 64 64',
                 ['grey1'] = '0 25 50', --'32 32 32',
                 ['dgrey1'] = '0 25 50', --'16 16 16',
                 ['dgrey2'] = '16 16 16',
                 ['red1'] = '165 8 46',
                 ['red2'] = '93 4 28',
                 ['red3'] = '200 13 66',
                 ['blue1'] = '0 120 169',
                 ['dblue1'] = '0 25 50',
                 ['backg'] = '5 0 10'
               }
    return gui
  end  
  ------------------------------------------------------------
      
  function f_Get_SSV(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i) / 255
    end
    gfx.r, gfx.g, gfx.b = t[1], t[2], t[3]
  end
  
  function ConvertColor(c)
    local r = (c & 255)
    local g = (c >> 8 & 255)
    local b = (c >> 16 & 255)
    return math.floor(r) .. ' ' .. math.floor(g) .. ' ' .. math.floor(b)
  end

  function ConvertColorString(s)
    if not s then return end
    local t = {}
    for i in s:gmatch("[%d%.]+") do 
      t[#t+1] = tonumber(i)
    end
    return t[1] + (t[2] << 8) + (t[3] << 16)
  end
  
  ------------------------------------------------------------
    
  function GUI_text(gui, xywh, text)
        f_Get_SSV(gui.color.white)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
  
  function GUI_textsm_LJ(gui, xywh, text, c, offs, limitx)
        f_Get_SSV(c)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len, newlen = gfx.measurestr(text), string.len(text)
        if limitx ~= nil and text_len+4 > limitx then
          for l = string.len(text), 1, -2 do
            text_len = gfx.measurestr(string.sub(text,0,l))+4
            if text_len <= limitx then newlen = l break end
          end
        end
        gfx.x, gfx.y = xywh.x+4,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(string.sub(text,1,newlen))
  end

  function GUI_textsm_RJ(gui, xywh, text, c, offs)
        f_Get_SSV(c)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+xywh.w-text_len, xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end
  
  function GUI_textC(gui, xywh, text, color, offs)
        f_Get_SSV(color)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len = gfx.measurestr(text)
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        gfx.drawstr(text)
  end

  function GUI_textC_LIM(gui, xywh, text, color, offs)
        f_Get_SSV(color)  
        gfx.a = 1 
        gfx.setfont(1, gui.fontname, gui.fontsz_knob + offs)
        local text_len, newlen = gfx.measurestr(text), string.len(text)
        if text_len > xywh.w then
          for l = string.len(text), 1, -2 do
            text_len = gfx.measurestr(string.sub(text,0,l))
            if text_len <= xywh.w then newlen = l break end
          end
        end
        if xywh.w < 20 then return end
        if newlen < string.len(text) then
          gfx.x, gfx.y = xywh.x+2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        else
          gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
        end
        gfx.drawstr(string.sub(text,1,newlen))
  end
  
  ------------------------------------------------------------
  
  function CropFXName(n)
  
    if n == nil then
      return ""
    else
      local fxn = string.match(n, ':(.+)%(')
      if fxn then
        return fxn
      else
        return n
      end
    end
    
  end
  
------------------------------------------------------------    

  function Strip_AddGFX()

    --loadimg and set imageidx in graphics_files and strip.graphics
    if tracks[track_select] then
    
      local strip
      
      if tracks[track_select].strip == -1 then
        strip = #strips+1
        strips[strip] = {track = tracks[track_select], page = page, {}}
        for i = 1,4 do
          strips[strip][i] = {surface_x = 0,
                             surface_y = 0,     
                             controls = {},
                             graphics = {}}
        end
        tracks[track_select].strip = strip
      else
        strip = tracks[track_select].strip
      end
      
      if graphics_files[gfx_select].imageidx == nil then  
        image_count = image_count + 1
        gfx.loadimg(image_count, graphics_path..graphics_files[gfx_select].fn)
        graphics_files[gfx_select].imageidx = image_count
      end

      local x,y
      x = math.floor((draggfx.x)/settings_gridsize)*settings_gridsize + math.floor(surface_offset.x/settings_gridsize)*settings_gridsize - math.floor((obj.sections[10].x)/settings_gridsize)*settings_gridsize
      y = math.floor((draggfx.y)/settings_gridsize)*settings_gridsize + math.floor(surface_offset.y/settings_gridsize)*settings_gridsize - math.floor((obj.sections[10].y)/settings_gridsize)*settings_gridsize
      local w, h = gfx.getimgdim(graphics_files[gfx_select].imageidx)      
      gfxnum = #strips[strip][page].graphics + 1
      strips[strip][page].graphics[gfxnum] = {fn = graphics_files[gfx_select].fn,
                                        imageidx = graphics_files[gfx_select].imageidx,
                                        x = x,
                                        y = y,
                                        w = w,
                                        h = h,
                                        scale = 1
                                       }
    end  

  end
  
------------------------------------------------------------    

  function Strip_AddParam()
  
    if tracks[track_select] then
    
      local strip
      
      if tracks[track_select].strip == -1 then
        strip = #strips+1
        strips[strip] = {track = tracks[track_select], page = page, {}}
        for i = 1,4 do
          strips[strip][i] = {surface_x = 0,
                             surface_y = 0,     
                             controls = {},
                             graphics = {}}
        end
        tracks[track_select].strip = strip
      else
        strip = tracks[track_select].strip
      end

      if ctl_files[knob_select].imageidx == nil then  
        image_count = image_count + 1
        gfx.loadimg(image_count, controls_path..ctl_files[knob_select].fn)
        ctl_files[knob_select].imageidx = image_count
      end
      
      local x,y
      x = round((dragparam.x)/settings_gridsize)*settings_gridsize
          + round(surface_offset.x/settings_gridsize)*settings_gridsize - round((obj.sections[10].x)/settings_gridsize)*settings_gridsize
      y = round((dragparam.y)/settings_gridsize)*settings_gridsize 
          + round(surface_offset.y/settings_gridsize)*settings_gridsize - round((obj.sections[10].y)/settings_gridsize)*settings_gridsize
      local w, h = gfx.getimgdim(ctl_files[knob_select].imageidx)
      ctlnum = #strips[strip][page].controls + 1
      strips[strip][page].controls[ctlnum] = {fxname=trackfx[trackfx_select].name,
                                              fxguid=trackfx[trackfx_select].guid, 
                                              fxnum=trackfx[trackfx_select].fxnum, 
                                              fxfound = true,
                                              param = trackfxparam_select,
                                              param_info = trackfxparams[trackfxparam_select],
                                              ctltype = ctltype_select,
                                              knob_select = knob_select,
                                              ctl_info = {fn = ctl_files[knob_select].fn,
                                                          frames = ctl_files[knob_select].frames,
                                                          imageidx = ctl_files[knob_select].imageidx, 
                                                          cellh = ctl_files[knob_select].cellh},
                                              x = x,
                                              y = y,
                                              w = w,
                                              scale = scale_select,
                                              xsc = x + math.floor(w/2 - (w*scale_select)/2),
                                              ysc = y + math.floor(ctl_files[knob_select].cellh/2 - (ctl_files[knob_select].cellh*scale_select)/2),
                                              wsc = w*scale_select,
                                              hsc = ctl_files[knob_select].cellh*scale_select,
                                              show_paramname = show_paramname,
                                              show_paramval = show_paramval,
                                              ctlname_override = '',
                                              textcol = textcol_select,
                                              textoff = textoff_select,
                                              textoffval = textoffval_select,
                                              textsize = textsize_select,
                                              val = GetParamValue(tracks[track_select].tracknum,
                                                                  trackfx[trackfx_select].fxnum,
                                                                  trackfxparam_select),
                                              defval = GetParamValue(tracks[track_select].tracknum,
                                                                  trackfx[trackfx_select].fxnum,
                                                                  trackfxparam_select),
                                              maxdp = maxdp_select,
                                              id = nil
                                              }
                                              
    end  
  
  end

  -------------------------------------------------------
  
  function PopulateStripFolders()
  
    strip_folders = {}
    sflist_offset = 0
    
    local i = 0
    local sf = reaper.EnumerateSubdirectories(strips_path,i)
    while sf ~= nil do
      strip_folders[i] = {fn = sf}
      i=i+1
      sf = reaper.EnumerateSubdirectories(strips_path,i)
    end
    
  end

  -------------------------------------------------------
  
  function PopulateStrips()
  
    strip_files = {}
    slist_offset = 0
    
    local i = 0
    local sf = reaper.EnumerateFiles(strips_path..'/'..strip_folders[stripfol_select].fn,i)
    while sf ~= nil do
      strip_files[i] = {fn = sf}
      i=i+1
      sf = reaper.EnumerateFiles(strips_path..'/'..strip_folders[stripfol_select].fn,i)
    end
    
  end

  -------------------------------------------------------
  
  function PopulateGFX()
  
    graphics_files = {}
    glist_offset = 0
    
    local i = 0
    local gf = reaper.EnumerateFiles(graphics_path,i)
    while gf ~= nil do
      graphics_files[i] = {fn = gf, imageidx = nil}
      i=i+1
      gf = reaper.EnumerateFiles(graphics_path,i)
    end
    
  end
  
  -------------------------------------------------------
  
  function PopulateControls()
  
    ctl_files = {}
    klist_offset = 0
    
    local i = 0
    local c = 0
    local kf = reaper.EnumerateFiles(controls_path,i)
    while kf ~= nil do
      if string.sub(kf,string.len(kf)-3) == '.knb' then
        local file
        file=io.open(controls_path..kf,"r")
        local content=file:read("*a")
        file:close()
        
        ctl_files[c] = unpickle(content)
         --= --{fn = kf, imageidx = nil, cellh = 100, frames = 101}
        if kf == '__default.knb' then
          ctl_files[c].imageidx = 0
          knob_select = c    
        end
        c = c + 1
      end
      i=i+1
      kf = reaper.EnumerateFiles(controls_path,i)
    end
    
  end
  
  -------------------------------------------------------

  function GetTrack(t)
  
    local tr
    if t == -1 then
      track = reaper.GetMasterTrack(0)
    else
      track = reaper.GetTrack(0, t)
    end
    return track
  
  end

  -------------------------------------------------------

  function PopulateTracks()
  
    tracks = {}
    for i = -1, reaper.CountTracks(0) do
      local track = GetTrack(i)
      if track ~= nil then
        local trname, _ = reaper.GetTrackState(track)
  
        tracks[i] = {name = trname,
                     guid = reaper.GetTrackGUID(track),
                     tracknum = i,
                     strip = -1
                     }
        if #strips > 0 then
          for j = 1, #strips do
            if strips[j].track.guid == tracks[i].guid then
              tracks[i].strip = j
              break
            end 
          end
        end
      end  
    end
  end
  
  function PopulateTrackFX()
  
    trackfx = {}
    trackfx_select = 0
    flist_offset = 0

    if track_select and tracks[track_select] then
      local track = GetTrack(tracks[track_select].tracknum)
      local fxc = reaper.TrackFX_GetCount(track)
      for i = 0, fxc-1 do
        local _, name = reaper.TrackFX_GetFXName(track,i,'')
        
        trackfx[i] = {name = name,
                      guid = reaper.TrackFX_GetFXGUID(track,i),
                      fxnum = i,
                      found = true}
      end
      PopulateTrackFXParams()
      ofxcnt = fxc
    end
    
  end

  function PopulateTrackFXParams()
  
    trackfxparams = {}
    trackfxparam_select = 0
    plist_offset = 0
    
    if track_select then
      local track = GetTrack(tracks[track_select].tracknum)
      for i = 0, reaper.TrackFX_GetNumParams(track, trackfx_select)-1 do
        local _, name = reaper.TrackFX_GetParamName(track, trackfx_select, i, '')
        
        trackfxparams[i] = {paramnum = i,
                            paramname = name}
      end
  
    end
  end
  
  function GUI_DrawTracks(obj, gui)
  
    gfx.dest = 1001
    if resize_display then
      gfx.setimgdim(1001,obj.sections[43].w+2, obj.sections[43].h)
    end
  
    T_butt_cnt = math.floor(obj.sections[43].h / butt_h) - 2
  
    local xywh = {x = 0,
                  y = 0,
                  w = obj.sections[43].w,
                  h = obj.sections[43].h}
    f_Get_SSV(gui.color.cbobg)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
      
    for i = 0, T_butt_cnt-1 do
    
      if tracks[i-1 + tlist_offset] then
        local xywh = {x = obj.sections[43].x,
                      y = (i+1) * butt_h,
                      w = obj.sections[43].w,
                      h = butt_h}
        local c = gui.color.white
        if track_select == i-1 + tlist_offset then
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          c = gui.color.black        
        end
        local nm = tracks[i-1 + tlist_offset].name
        if nm == '' then
          nm = '[unnamed track]'
        end
        GUI_textsm_LJ(gui, xywh, tracks[i-1 + tlist_offset].tracknum+1 ..' - '..nm, c, -4, plist_w)
                    
      end                      
    end           

    local xywh = {x = obj.sections[43].x,
                  y = 0,
                  w = obj.sections[43].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[43].x,
                  y = obj.sections[43].h - butt_h,
                  w = obj.sections[43].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

  end

  ------------------------------------------------------------
  
  function GetFXEnabled(tracknum, fxnum)
  
    local enb = true
    local tr = GetTrack(tracknum)
    if tr then
      enb = reaper.TrackFX_GetEnabled(track, fxnum)
      if enb then
        --check global track bypass
        local _, flags = reaper.GetTrackState(tr)
        if flags then
          enb = flags&4==4
        end
      end
    end
    return enb
  
  end
  
  ------------------------------------------------------------

  function GUI_DrawFXParams(obj, gui)
    if track_select == nil then return end
    gfx.dest = 1001
    if resize_display then
      gfx.setimgdim(1001,obj.sections[43].w+2, obj.sections[43].h)
    end
    
    F_butt_cnt = math.floor(obj.sections[41].h / butt_h) - 3
    
    local xywh = {x = obj.sections[43].x,
                  y = 0,
                  w = obj.sections[43].w,
                  h = obj.sections[43].h}
    f_Get_SSV(gui.color.cbobg)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    for i = 0, F_butt_cnt-1 do
    
      if trackfx[i + flist_offset] then
        local xywh = {x = obj.sections[41].x,
                      y = obj.sections[41].y +2+ (i+1) * butt_h,
                      w = obj.sections[41].w,
                      h = butt_h}
        local c
        local bypassed = not GetFXEnabled(tracks[track_select].tracknum, i+ flist_offset)
        if bypassed == false then        
          c = gui.color.white
        else
          c = gui.color.red        
        end
        if trackfx_select == i + flist_offset then
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          if bypassed == false then        
            c = gui.color.black
          end
        end
        GUI_textsm_LJ(gui, xywh, CropFXName(trackfx[i + flist_offset].name), c, -4, plist_w)
      else
        break
      end
              
    end

    local xywh = {x = obj.sections[41].x,
                  y = obj.sections[41].y,
                  w = obj.sections[41].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1)
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[41].x,
                  y = obj.sections[41].y + obj.sections[41].h - butt_h*2,
                  w = obj.sections[41].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

    --Params
    P_butt_cnt = math.floor(obj.sections[42].h / butt_h) - 3
    for i = 0, P_butt_cnt do
    
      if trackfxparams[i + plist_offset] then
        local xywh = {x = obj.sections[42].x,
                      y = obj.sections[42].y +2 + (i+1) * butt_h,
                      w = obj.sections[42].w,
                      h = butt_h}  
        local c = gui.color.white
        --if trackfxparam_select == i + plist_offset then
        if tfxp_sel and tfxp_sel[i + plist_offset] then  
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          c = gui.color.black        
        end
        GUI_textsm_LJ(gui, xywh, trackfxparams[i + plist_offset].paramname, c, -4, plist_w)
      else
        break
      end
              
    end

    local xywh = {x = obj.sections[42].x,
                  y = obj.sections[42].y,
                  w = obj.sections[42].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[42].x,
                  y = obj.sections[43].h-butt_h,
                  w = obj.sections[42].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

  end

  ------------------------------------------------------------
  
  function GUI_DrawGraphicsChooser(obj, gui)

    gfx.dest = 1001
    if resize_display then
      gfx.setimgdim(1001,obj.sections[43].w+2, obj.sections[43].h)
    end

    local butt_cnt = math.floor((obj.sections[44].h) / butt_h)  
    local xywh = {x = 0,
                  y = 0,
                  w = obj.sections[43].w,
                  h = obj.sections[43].h}
    f_Get_SSV(gui.color.cbobg)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    G_butt_cnt = math.floor(obj.sections[44].h / butt_h) - 2
      
    for i = 0, butt_cnt-1 do
    
      if graphics_files[i + glist_offset] then
        local xywh = {x = obj.sections[44].x,
                      y = butt_h+2 +4+ (i+1) * butt_h,
                      w = obj.sections[44].w,
                      h = butt_h}
        local c = gui.color.white
        if gfx_select == i + glist_offset then
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          c = gui.color.black        
        end
        GUI_textsm_LJ(gui, xywh, graphics_files[i + glist_offset].fn, c, -4, plist_w)
                    
      end                      
    end           

    local xywh = {x = obj.sections[44].x,
                  y = butt_h+4,
                  w = obj.sections[44].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[44].x,
                  y = obj.sections[43].h-butt_h,
                  w = obj.sections[44].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)
  
  end

  ------------------------------------------------------------
  
  function GUI_DrawStripChooser(obj, gui)

    gfx.dest = 1001
    if resize_display then
      gfx.setimgdim(1001,obj.sections[43].w+2, obj.sections[43].h)
    end

    local xywh = {x = 0,
                  y = 0,
                  w = obj.sections[43].w,
                  h = obj.sections[43].h}
    f_Get_SSV(gui.color.cbobg)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    SF_butt_cnt = math.floor(obj.sections[47].h / butt_h) - 2
    for i = 0, SF_butt_cnt-1 do
    
      if strip_folders[i + sflist_offset] then
        local xywh = {x = obj.sections[47].x,
                      y = obj.sections[47].y+2 + (i) * butt_h,
                      w = obj.sections[47].w,
                      h = butt_h}
        local c = gui.color.white
        if stripfol_select == i + sflist_offset then
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          c = gui.color.black        
        end
        GUI_textsm_LJ(gui, xywh, strip_folders[i + sflist_offset].fn, c, -4, plist_w)
                    
      end                      
    end           

    local xywh = {x = obj.sections[47].x,
                  y = obj.sections[47].y-butt_h,
                  w = obj.sections[47].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[47].x,
                  y = obj.sections[47].y+obj.sections[47].h-butt_h,
                  w = obj.sections[47].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

    S_butt_cnt = math.floor(obj.sections[46].h / butt_h) - 2
    for i = 0, S_butt_cnt-1 do
    
      if strip_files[i + slist_offset] then
        local xywh = {x = obj.sections[46].x,
                      y = obj.sections[46].y+2 + (i+1) * butt_h,
                      w = obj.sections[46].w,
                      h = butt_h}
        local c = gui.color.white
        if strip_select == i + slist_offset then
          f_Get_SSV(gui.color.white)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)

          c = gui.color.black        
        end
        GUI_textsm_LJ(gui, xywh, strip_files[i + slist_offset].fn, c, -4, plist_w)
                    
      end                      
    end           

    local xywh = {x = obj.sections[46].x,
                  y = obj.sections[46].y+2,
                  w = obj.sections[46].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
     
    local xywh = {x = obj.sections[46].x,
                  y = obj.sections[43].h-butt_h,
                  w = obj.sections[46].w,
                  h = butt_h}
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

  end
      
  ------------------------------------------------------------

  function GUI_DrawControlBackG(obj, gui)

    gfx.dest = 1004
    if resize_display then
      if surface_size.x == -1 then
        gfx.setimgdim(1000,obj.sections[10].w, obj.sections[10].h)
        gfx.setimgdim(1004,obj.sections[10].w, obj.sections[10].h)
        --f_Get_SSV('0 0 0')
        --gfx.rect(0,0,obj.sections[10].w,obj.sections[10].h)
      end
    end

    gfx.a = 1
    f_Get_SSV('16 16 16')
    if surface_size.limit then
      gfx.rect(0,
               0, 
               surface_size.w,
               surface_size.h, 1, 1)      
    else
      gfx.rect(obj.sections[10].x,
               obj.sections[10].y, 
               obj.sections[10].w,
               obj.sections[10].h, 1, 1)
    end
                 
    if tracks and tracks[track_select] and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page] then
    
      if #strips[tracks[track_select].strip][page].graphics > 0 then
      
        for i = 1, #strips[tracks[track_select].strip][page].graphics do
        
          local x = strips[tracks[track_select].strip][page].graphics[i].x
          local y = strips[tracks[track_select].strip][page].graphics[i].y
          if not surface_size.limit then
            x = x + surface_offset.x 
            y = y + surface_offset.y 
          end
          local w = strips[tracks[track_select].strip][page].graphics[i].w
          local h = strips[tracks[track_select].strip][page].graphics[i].h
          local imageidx = strips[tracks[track_select].strip][page].graphics[i].imageidx
          
          local yoff = 0
          local xoff = 0
          if not surface_size.limit then
            if x+w > obj.sections[10].x + obj.sections[10].w then
              w = obj.sections[10].x + obj.sections[10].w - x
            end
            if x < obj.sections[10].x then
              xoff = obj.sections[10].x - x
            end
            if y+h > obj.sections[10].y + obj.sections[10].h then
              h = obj.sections[10].y + obj.sections[10].h - y
            end
            if y < obj.sections[10].y then
              yoff = obj.sections[10].y - y
            end
          end
          gfx.blit(imageidx,1,0, xoff, yoff, w, h-yoff, x+xoff, y+yoff)

        end
      end      
    end

    if settings_showgrid and mode ~= 0 then
      local gs = settings_gridsize
      if gs == 1 then gs = ogrid end
      f_Get_SSV('0 0 0')
      gfx.a = 0.9
      for i = 0, surface_size.w, gs do
        gfx.line(i,0,i,surface_size.h)
      end
      for i = 0, surface_size.h, gs do
        gfx.line(0,i,surface_size.h,i)
      end
    end
    
    gfx.dest = 1    
  end

  ------------------------------------------------------------

  function GUI_DrawCtlOptions(obj, gui)

    gfx.dest = 1

    local xywh = {x = obj.sections[45].x,
                  y = obj.sections[45].y,
                  w = obj.sections[45].w,
                  h = obj.sections[45].h}
    
    f_Get_SSV('0 0 0')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    
    xywh.h = butt_h     
    f_Get_SSV(gui.color.white)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    GUI_textC(gui,xywh,'CTL OPTIONS',gui.color.black,-2)
    
    xywh = {x = obj.sections[45].x,
            y = obj.sections[45].y+butt_h,
            w = obj.sections[45].w,
            h = obj.sections[45].h}
    
    local iidx = 1023

    if knob_select > -1 then
      if ctl_files[knob_select].imageidx ~= nil then
        iidx = ctl_files[knob_select].imageidx
      else
        gfx.loadimg(1023, controls_path..ctl_files[knob_select].fn)
      end
      local w, _ = gfx.getimgdim(iidx)
      gfx.a = 1
      gfx.blit(iidx,scale_select,0, 0, 0, w, ctl_files[knob_select].cellh, xywh.x + (xywh.w/2-(w*scale_select)/2), xywh.y + (62.5 - (ctl_files[knob_select].cellh*scale_select)/2))
    end
        
    GUI_DrawSliderH(gui, 'SCALE', obj.sections[50], gui.color.black, gui.color.white, (scale_select-0.5)*2)
    GUI_DrawTick(gui, 'SHOW NAME', obj.sections[52], gui.color.white, show_paramname)
    GUI_DrawTick(gui, 'SHOW VALUE', obj.sections[53], gui.color.white, show_paramval)
    GUI_DrawColorBox(gui, 'TEXT COL', obj.sections[54], gui.color.white, textcol_select)
    GUI_DrawButton(gui, ctltype_table[ctltype_select], obj.sections[55], gui.color.white, gui.color.black, true)
    GUI_DrawSliderH(gui, 'OFFSET', obj.sections[56], gui.color.black, gui.color.white, (textoff_select+150)/300)
    GUI_DrawSliderH(gui, 'VAL OFF', obj.sections[65], gui.color.black, gui.color.white, (textoffval_select+50)/100)
    GUI_DrawSliderH(gui, 'F SIZE', obj.sections[58], gui.color.black, gui.color.white, (textsize_select+2)/35)
    GUI_DrawSliderH(gui, 'DEF VAL', obj.sections[57], gui.color.black, gui.color.white, defval_select)
    GUI_DrawButton(gui, 'SET', obj.sections[51], gui.color.white, gui.color.black, true)
    GUI_DrawButton(gui, 'EDIT NAME', obj.sections[59], gui.color.white, gui.color.black, true)
    local mdptxt = maxdp_select
    if maxdp_select < 0 then
      mdptxt = 'OFF'
    end
    GUI_DrawButton(gui, mdptxt, obj.sections[66], gui.color.white, gui.color.black, true, 'MAX DP')
    
  end
 
  function GUI_DrawSliderH(gui, t, b, colb, cols, v)

    local xywh = {x=b.x-10,y=b.y-2,w=1,h=b.h}
    GUI_textsm_RJ(gui,xywh,t,cols,-4)

    f_Get_SSV(cols)
    gfx.a = 1 
    gfx.rect(b.x,
             b.y, 
             b.w,
             b.h, 1 )
    f_Get_SSV(colb)
    gfx.a = 1
    local w = (b.w-2) - (b.w-2) * v
    if w > 0 then
      gfx.rect(b.x+1 + (b.w-2)-w,
               b.y+1, 
               w,
               b.h-2, 1 )
    end
    
  end

  function GUI_DrawButton(gui, t, b, colb, colt, v, opttxt)

    if opttxt then
      local xywh = {x=b.x-10,y=b.y-2,w=1,h=b.h}
      GUI_textsm_RJ(gui,xywh,opttxt,colb,-4)
    end
      
    local f = 1
    if v == nil or v == false then
      f = 0
    end
    f_Get_SSV(colb)
    gfx.a = 1 
    gfx.rect(b.x,
             b.y, 
             b.w,
             b.h, f)
    if f == 0 then
      colt = colb
    end
    local xywh = {x=b.x,y=b.y-1,w=b.w,h=b.h}
    GUI_textC(gui,xywh,t,colt,-4)
  
  end
  
  function GUI_DrawTick(gui, t, b, col, v)
  
    local xywh = {x=b.x-10,y=b.y-2,w=1,h=b.h}
    GUI_textsm_RJ(gui,xywh,t,col,-4)

    local f = 1
    if v == nil or v == false then
      f = 0
    end
    f_Get_SSV(col)
    gfx.a = 1 
    gfx.rect(b.x,
             b.y, 
             b.w,
             b.h, f)
    f_Get_SSV(gui.color.black)
    gfx.line(b.x,b.y,b.x+b.w,b.y+b.h)
    gfx.line(b.x,b.y+b.h,b.x+b.w,b.y)
  
  end

  function GUI_DrawColorBox(gui, t, b, col, cols)
  
    local xywh = {x=b.x-10,y=b.y-2,w=1,h=b.h}
    GUI_textsm_RJ(gui,xywh,t,col,-4)

    local f = 1
    f_Get_SSV(cols)
    gfx.a = 1 
    gfx.rect(b.x,
             b.y, 
             b.w,
             b.h, f)
    f_Get_SSV(col)
    gfx.a = 1 
    gfx.rect(b.x,
             b.y, 
             b.w,
             b.h, 0)
  
  end
    
  ------------------------------------------------------------
  function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  end

  function roundX(num, idp)
    local s, e = string.find(num,'%d+.%d+')
    if s and e then  
      local n = string.sub(num,s,e)
      if n then
        local mult = 10^(idp or 0)
        local res = math.floor(n * mult + 0.5) / mult
        if idp == 0 then
          res = string.match(tostring(res),'%d+')
        end
        return string.sub(num,1,s-1) .. res .. string.sub(num,e+1)
      else
        return num
      end
    else
      return num
    end
  end
  
  function nz(val, d)
    if val == nil then return d else return val end
  end
  
  ------------------------------------------------------------

  function GUI_DrawControls(obj, gui)

    gfx.dest = 1000
    gfx.a = 1
    xywharea = {}
    
    if update_gfx or update_bg then
      if mode == 1 and submode == 0 then
        gfx.a = 1
        f_Get_SSV('0 0 0')
        if surface_size.limit then
          gfx.rect(0,
                   0, 
                   surface_size.w,
                   surface_size.h, 1, 1)      
        else
          gfx.rect(obj.sections[10].x,
                   obj.sections[10].y, 
                   obj.sections[10].w,
                   obj.sections[10].h, 1, 1)
        end
              
        gfx.a = 0.5
      else
        gfx.a = 1
      end
      if surface_size.limit then
        gfx.blit(1004,1,0,0,0,surface_size.w,surface_size.h,0,0)    
      else
        gfx.blit(1004,1,0,0,0,obj.sections[10].w,obj.sections[10].h,obj.sections[10].x,obj.sections[10].y)
      end
    end
        
    if tracks[track_select] and strips[tracks[track_select].strip] then
    
      if #strips[tracks[track_select].strip][page].controls > 0 then

        local track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
        if track == nil then 
          if CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip) then
            track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
          else
            return 
          end 
        end
      
        for i = 1, #strips[tracks[track_select].strip][page].controls do
        
          if update_gfx or strips[tracks[track_select].strip][page].controls[i].dirty or force_gfx_update then
            strips[tracks[track_select].strip][page].controls[i].dirty = false
            
            local scale = strips[tracks[track_select].strip][page].controls[i].scale
            local x = strips[tracks[track_select].strip][page].controls[i].x 
            local y = strips[tracks[track_select].strip][page].controls[i].y
            local px = strips[tracks[track_select].strip][page].controls[i].xsc 
            local py = strips[tracks[track_select].strip][page].controls[i].ysc
            local w = strips[tracks[track_select].strip][page].controls[i].w
            local h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh
  
            local visible = true
            if surface_size.limit == false then
              if x+w < obj.sections[10].x or x > obj.sections[10].x + obj.sections[10].w or y+h < obj.sections[10].y or y > obj.sections[10].y + obj.sections[10].h then
                visible = false
              end
            end
            
            if visible then
              local gh = h
              local val = math.floor(100*strips[tracks[track_select].strip][page].controls[i].val)
              
              local fxnum = nz(strips[tracks[track_select].strip][page].controls[i].fxnum,-1)
              local param = strips[tracks[track_select].strip][page].controls[i].param
              local pname = strips[tracks[track_select].strip][page].controls[i].param_info.paramname
              local iidx = strips[tracks[track_select].strip][page].controls[i].ctl_info.imageidx
              local spn = strips[tracks[track_select].strip][page].controls[i].show_paramname
              local spv = strips[tracks[track_select].strip][page].controls[i].show_paramval
              local tc = strips[tracks[track_select].strip][page].controls[i].textcol
              local toff = math.floor(strips[tracks[track_select].strip][page].controls[i].textoff)
              local toffv = math.floor(strips[tracks[track_select].strip][page].controls[i].textoffval)
              local tsz = nz(strips[tracks[track_select].strip][page].controls[i].textsize,0)
              local frames = math.floor(strips[tracks[track_select].strip][page].controls[i].ctl_info.frames)
              local ctltype = strips[tracks[track_select].strip][page].controls[i].ctltype
              local ctlnmov = strips[tracks[track_select].strip][page].controls[i].ctlname_override
              local found = strips[tracks[track_select].strip][page].controls[i].fxfound
              local maxdp = nz(strips[tracks[track_select].strip][page].controls[i].maxdp,-1)
              
              if fxnum == nil then return end
    
              local v2 = reaper.TrackFX_GetParamNormalized(track,fxnum,param)
              
              local val2 = F_limit(round(frames*v2),0,frames-1)
              
              if mode == 1 and submode == 1 then
                gfx.a = 0.5
              else
                gfx.a = 1
              end
              
              if ctltype == 3 then
                --invert button
                val2 = 1-val2
              end
              if not found then
                gfx.a = 0.2
              end

              gfx.setfont(1, gui.fontname, gui.fontsz_knob +tsz-4)
              local _, th_a = gfx.measurestr('|')
              local to = th_a

              local Disp_ParamV
              local Disp_Name
              if not found then
                Disp_Name = CropFXName(strips[tracks[track_select].strip][page].controls[i].fxname)
                Disp_ParamV = 'PLUGIN NOT FOUND'
                tc = gui.color.red
                val2 = 0
              else
                if nz(ctlnmov,'') == '' then
                  _, Disp_Name = reaper.TrackFX_GetParamName(track, fxnum, param, "")
                else
                  Disp_Name = ctlnmov
                end
                _, Disp_ParamV = reaper.TrackFX_GetFormattedParamValue(track, fxnum, param, "")
                if maxdp > -1 then
                  Disp_ParamV = roundX(Disp_ParamV, maxdp)                  
                end
              end

              local mid = x+(w/2)

              local text_len1x, text_len1y = gfx.measurestr(Disp_Name)
              local text_len2x, text_len2y = gfx.measurestr(Disp_ParamV)

              local xywh1 = {x = math.floor(mid-(text_len1x/2)), y = math.floor(y+(h/2)-toff-1), w = text_len1x, h = th_a+2}
              local xywh2 = {x = math.floor(mid-(text_len2x/2)), y = math.floor(y+(h/2)-to+toff+toffv-1), w = text_len2x, h = th_a+2}
              
              local tl1 = nz(strips[tracks[track_select].strip][page].controls[i].tl1,text_len1x)
              local tl2 = nz(strips[tracks[track_select].strip][page].controls[i].tl2,text_len2x)
              local tx1, tx2, th = math.ceil(mid-(tl1/2)),
                                   math.ceil(mid-(tl2/2)),th_a --gui.fontsz_knob+tsz-4
              if not update_gfx and not update_bg and surface_size.limit then
                gfx.blit(1004,1,0, px,
                                   py,
                                   w*scale,
                                   (h)*scale,
                                   px,
                                   py)
                if spn and h > 10 then                   
                  gfx.blit(1004,1,0, tx1,
                                     xywh1.y,
                                     tl1,
                                     th_a,
                                     mid-(tl1/2),
                                     xywh1.y)
                end
                if spv and h > gh-10 then                
                  gfx.blit(1004,1,0, tx2-5,
                                     xywh2.y,
                                     tl2+10,
                                     th_a,
                                     mid-(tl2/2)-5,
                                     xywh2.y)
                end
              end
              if not reaper.TrackFX_GetEnabled(track, fxnum) and pname ~= 'Bypass' then
                gfx.a = 0.5
              end              
              gfx.blit(iidx,scale,0, 0, (val2)*gh, w, h, px, py)
              
              strips[tracks[track_select].strip][page].controls[i].tl1 = text_len1x
              strips[tracks[track_select].strip][page].controls[i].tl2 = text_len2x
              
              if w > strips[tracks[track_select].strip][page].controls[i].w/2 then
                if spn and h > 10 then
                  GUI_textC(gui,xywh1, Disp_Name,tc,-4 + tsz)
                end
                if spv and h > gh-10 then
                  GUI_textC(gui,xywh2, Disp_ParamV,tc,-4 + tsz)          
                end
              end
            
              if reass_param == i then
                f_Get_SSV(gui.color.red)
                gfx.a = 0.8
                gfx.roundrect(x, y, w, h, 8, 1, 0)
              end
              
              if not update_gfx and not update_bg and update_ctls then
              
                --just blit control area to main backbuffer - create area table
                local al = math.min(px, xywh1.x)
                al = math.min(al, xywh2.x)
                local ar = math.max(px+w*scale, tx1+tl1)
                ar = math.max(ar, tx2+tl2)
                local at = math.min(py, xywh1.y)
                at = math.min(at, xywh2.y)
                local ab = math.max(py+(h)*scale,xywh1.y+th)
                ab = math.max(ab, xywh2.y+th)
                xywharea[#xywharea+1] = {x=al,y=at,w=ar-al,h=ab-at,r=ar,b=ab}
              end
            end
          end
        end
        
        if not update_gfx and not update_bg and update_ctls then
          --loop through blit area table - blit to backbuffer
          local ox, oy = 0,0
          if surface_offset.x < 0 then ox=-1 end
          if surface_offset.y < 0 then oy=-1 end
          if #xywharea > 0 then
            gfx.dest = 1
            for i = 1, #xywharea do
              local xx = (xywharea[i].x + obj.sections[10].x - surface_offset.x + ox)
              local yy = (xywharea[i].y + obj.sections[10].y - surface_offset.y + oy)
              if xx+xywharea[i].w < obj.sections[10].x or yy+xywharea[i].h < obj.sections[10].y
                 or yy > obj.sections[10].y+obj.sections[10].h or xx > obj.sections[10].x+obj.sections[10].w then
              else
                --if lockw > 0 then                
                  if xx < obj.sections[10].x then
                    xywharea[i].x = xywharea[i].x + (obj.sections[10].x - xx)
                    xywharea[i].w = xywharea[i].w  - (obj.sections[10].x - xx)
                    xx = obj.sections[10].x
                  end
                  if xx + xywharea[i].w > obj.sections[10].x+obj.sections[10].w then
                    xywharea[i].w = (obj.sections[10].x+obj.sections[10].w)-xx
                  end
                --end
                --if lockh > 0 then
                  if yy < obj.sections[10].y then
                    xywharea[i].y = xywharea[i].y + (obj.sections[10].y - yy)
                    xywharea[i].h = xywharea[i].h  - (obj.sections[10].y - yy)
                    yy = obj.sections[10].y
                  end
                  if yy + xywharea[i].h > obj.sections[10].y+obj.sections[10].h then
                    xywharea[i].h = (obj.sections[10].y+obj.sections[10].h)-yy
                  end
                --end
                gfx.blit(1000,1,0, xywharea[i].x,
                                   xywharea[i].y,
                                   xywharea[i].w,
                                   xywharea[i].h,
                                   xx ,
                                   yy)
              end
            end
          end
        end
        
      end
    end
    force_gfx_update = false
    
  end
  
  ------------------------------------------------------------

  function CalcSelRect()
  
    if strips and tracks[track_select] and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page] then
      if #strips[tracks[track_select].strip][page].controls > 0 then
        local i = ctl_select[1].ctl
        local x = strips[tracks[track_select].strip][page].controls[i].x 
        local y = strips[tracks[track_select].strip][page].controls[i].y
        local w = strips[tracks[track_select].strip][page].controls[i].w
        local h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh
        local rx, ry = x+w, y+h
        if #ctl_select > 1 then
          for i = 2, #ctl_select do
            j = ctl_select[i].ctl
    
            x = math.min(x, strips[tracks[track_select].strip][page].controls[j].x)
            y = math.min(y, strips[tracks[track_select].strip][page].controls[j].y)
            rx = math.max(rx, strips[tracks[track_select].strip][page].controls[j].x + strips[tracks[track_select].strip][page].controls[j].w)
            ry = math.max(ry, strips[tracks[track_select].strip][page].controls[j].y + strips[tracks[track_select].strip][page].controls[j].ctl_info.cellh)
            
          end
        end
        local selrect = {x = x, y = y, w = rx-x, h = ry-y}
        return selrect
      end
    end
    
    return nil
    
  end

  function CalcCtlRect()

    local rect = nil  
    if strips and tracks[track_select] and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page] then
      if #strips[tracks[track_select].strip][page].controls > 0 then
        local i = 1
        local x = strips[tracks[track_select].strip][page].controls[i].x 
        local y = strips[tracks[track_select].strip][page].controls[i].y
        local w = strips[tracks[track_select].strip][page].controls[i].w
        local h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh
        local rx, ry = x+w, y+h
        if #strips[tracks[track_select].strip][page].controls > 1 then
          for j = 2, #strips[tracks[track_select].strip][page].controls do
    
            x = math.min(x, strips[tracks[track_select].strip][page].controls[j].x)
            y = math.min(y, strips[tracks[track_select].strip][page].controls[j].y)
            rx = math.max(rx, strips[tracks[track_select].strip][page].controls[j].x + strips[tracks[track_select].strip][page].controls[j].w)
            ry = math.max(ry, strips[tracks[track_select].strip][page].controls[j].y + strips[tracks[track_select].strip][page].controls[j].ctl_info.cellh)
            
          end
        end
        
        rect = {x = x, y = y, w = rx-x, h = ry-y}
      end
    end 

    return rect     
  end

  function GUI_drawpeak(obj, gui)
    
    if track_select == nil then return end
  
    gfx.dest = 1
    local tr = GetTrack(tracks[track_select].tracknum)
    local lc = F_limit((reaper.Track_GetPeakInfo(tr,0)),0,1)
    local rc = F_limit(reaper.Track_GetPeakInfo(tr,1),0,1)
    
    w, _ = gfx.getimgdim(1020)
    local h = 200
    gfx.blit(1020,1,0,0,math.ceil(lc*99) *h,w,h,gfx1.main_w - w*2+4,gfx1.main_h - h - 2)          
    gfx.blit(1020,1,0,0,math.ceil(rc*99) *h,w,h,gfx1.main_w - w-2,gfx1.main_h - h - 2)          
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
    gfx1.main_w - w*2+4,gfx1.main_h - h - 2, w*2,h,
    gfx1.main_w - w*2+4,gfx1.main_h - h - 2, w*2,h)
    gfx.dest = 1
  
  end

  ------------------------------------------------------------
  
  function GUI_draw(obj, gui)
    gfx.mode =4
    
    if update_gfx or update_surface or update_sidebar or update_topbar or update_ctlopts or update_ctls or update_bg or update_settings then    
      local p = 0
    
      --DBG(tostring(update_gfx)..tostring(update_surface)..tostring(update_sidebar)..tostring(update_topbar)..tostring(update_ctlopts)..tostring(update_ctls)..tostring(update_bg)..tostring(update_settings))
    
      gfx.dest = 1
      if update_gfx then
        gfx.setimgdim(1, -1, -1)  
        gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)
      end
            
      if resize_display then
        gfx.setimgdim(1002,obj.sections[45].w, obj.sections[45].h)
      end
      
      if mode == 0 then
        --Live
        if update_gfx or (surface_size.limit == false and update_surface) then
          GUI_DrawControlBackG(obj, gui)
          GUI_DrawControls(obj, gui)
        elseif update_ctls then        
          GUI_DrawControls(obj, gui)
        end
        if update_gfx or update_sidebar then        
          GUI_DrawTracks(obj, gui)
        end
        
        gfx.dest = 1
        
        if update_gfx or update_surface or update_bg then
          --local w, h = obj.sections[10].w, lockh
          --local x, y = obj.sections[10].x + obj.sections[10].w/2 - w/2, obj.sections[10].y + (obj.sections[10].h/2) - h/2
          gfx.blit(1000,1,0,surface_offset.x,
                            surface_offset.y,
                            obj.sections[10].w,
                            obj.sections[10].h,
                            obj.sections[10].x,
                            obj.sections[10].y)
        
        end
        
        if plist_w > 0 then                  
          gfx.blit(1001,1,0,0,0,obj.sections[43].w+2,obj.sections[43].h,0,butt_h)
        end
        
        f_Get_SSV(gui.color.black)
        gfx.rect(0,
                 obj.sections[11].y, 
                 gfx1.main_w,
                 obj.sections[11].h+2, 1, 1)

        if update_gfx then
          if lockh > 0 or lockw > 0 then
            UpdateLEdges()
          end
        end
        
      elseif mode == 1 then        
        --Edit
        
        if submode == 0 then

          if update_gfx or (surface_size.limit == false and update_surface) or update_bg then
            GUI_DrawControlBackG(obj, gui)
            GUI_DrawControls(obj, gui)
          elseif update_ctls then        
            GUI_DrawControls(obj, gui)
          end
          if update_gfx or update_sidebar then        
            GUI_DrawFXParams(obj, gui)
          end
          
          if show_ctloptions and ctl_select ~= nil then
            --GUI_DrawCtlOptions(obj, gui)            
          end

          gfx.dest = 1
          gfx.a = 1
          gfx.blit(1000,1,0,surface_offset.x,
                            surface_offset.y,
                            obj.sections[10].w,
                            obj.sections[10].h,
                            obj.sections[10].x,
                            obj.sections[10].y)
          gfx.blit(1001,1,0,0,0,obj.sections[43].w+2,obj.sections[43].h,0,butt_h+2)
          
          if dragparam ~= nil then
            if reass_param == nil then
              local x, y = dragparam.x, dragparam.y
              
              gfx.a = 0.7
              local iidx = ctl_files[knob_select].imageidx
              if iidx == nil or ksel_loaded == false then
                ksel_loaded = true
                gfx.loadimg(1023, controls_path..ctl_files[knob_select].fn)
                iidx = 1023
              elseif iidx == nil then
                iidx = 1023
              end
              local w, _ = gfx.getimgdim(iidx)
              local h = ctl_files[knob_select].cellh
              gfx.blit(iidx,scale_select,0,0,p*h,w,ctl_files[knob_select].cellh,x+ w/2-w*scale_select/2,y+ h/2-h*scale_select/2 )
              f_Get_SSV(gui.color.yellow)
              gfx.a = 1
              if surface_size.limit then
                gfx.roundrect(x, y ,w, h, 8, 1, 0)
              else
                gfx.roundrect(x + surface_offset.x, y + surface_offset.y, w, h, 8, 1, 0)              
              end
            end
          end
          
          if lasso ~= nil then
            gfx.a = 0.2
            f_Get_SSV(gui.color.blue)
            local l = {l = lasso.l, r = lasso.r, t = lasso.t, b = lasso.b}
            if lasso.r < lasso.l then
              l.l = lasso.r
              l.r = lasso.l
            end
            if lasso.b < lasso.t then
              l.b = lasso.t
              l.t = lasso.b          
            end
            gfx.rect(l.l,
                     l.t, 
                     l.r-l.l,
                     l.b-l.t, 1, 1)
          end
          
          if ctl_select ~= nil then
            selrect = CalcSelRect()
            if selrect then
              f_Get_SSV(gui.color.yellow)
              gfx.a = 1
              gfx.roundrect(selrect.x - surface_offset.x + obj.sections[10].x, selrect.y - surface_offset.y + obj.sections[10].y, selrect.w, selrect.h, 8, 1, 0)
            end
          end
          
          if update_gfx then
            if lockh > 0 or lockw > 0 then
              UpdateLEdges()
            end
          end
                    
          if show_ctloptions and ctl_select ~= nil then
            
            local w,h = gfx.getimgdim(1021)
            gfx.a = 0.5
            gfx.blit(1021,1,0,0,0,w,h,obj.sections[60].x,obj.sections[60].y)
            GUI_DrawCtlOptions(obj, gui)            
          end
                  
        
        elseif submode == 1 then
        
          if update_gfx or (surface_size.limit == false and update_surface) or update_bg then
            GUI_DrawControlBackG(obj, gui)
            GUI_DrawControls(obj, gui)
          elseif update_ctls then        
            GUI_DrawControls(obj, gui)
          end
                    
          if update_gfx or update_sidebar then        
            GUI_DrawGraphicsChooser(obj, gui)
          end
          
          gfx.dest = 1
          gfx.a = 1
          gfx.blit(1000,1,0,surface_offset.x,
                            surface_offset.y,
                            obj.sections[10].w,
                            obj.sections[10].h,
                            obj.sections[10].x,
                            obj.sections[10].y)
          
          gfx.blit(1001,1,0,0,0,obj.sections[43].w+2,obj.sections[43].h,0,butt_h)

          if draggfx ~= nil then
            local x, y = draggfx.x, draggfx.y
            local w, h = gfx.getimgdim(1023)
            gfx.a = 0.5
            
            gfx.blit(1023,1,0,0,0,w,h,x,y)          
          end

          if update_gfx then
            if lockh > 0 or lockw > 0 then
              UpdateLEdges()
            end
          end

          if gfx_select ~= nil then
            local w,h = gfx.getimgdim(1021)
            gfx.a = 0.5
            gfx.blit(1021,1,0,0,0,w,h,obj.sections[60].x,obj.sections[60].y)           
          end
                  
        elseif submode == 2 then

          if update_gfx or (surface_size.limit == false and update_surface) or update_bg then
            GUI_DrawControlBackG(obj, gui)
            GUI_DrawControls(obj, gui)
          elseif update_ctls then        
            GUI_DrawControls(obj, gui)
          end
          GUI_DrawStripChooser(obj, gui)

          gfx.dest = 1
          gfx.a = 1
          gfx.blit(1000,1,0,surface_offset.x,
                            surface_offset.y,
                            obj.sections[10].w,
                            obj.sections[10].h,
                            obj.sections[10].x,
                            obj.sections[10].y)
          gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)          
          
          if dragstrip ~= nil then
            local x, y = dragstrip.x, dragstrip.y
            local w, h = gfx.getimgdim(1022)
            gfx.a = 0.5
            
            gfx.blit(1022,1,0,0,0,w,h,x,y)          
          end

          if ctl_select ~= nil then
            selrect = CalcSelRect()
            if selrect then
              f_Get_SSV(gui.color.yellow)
              gfx.a = 1
              gfx.roundrect(selrect.x - surface_offset.x+obj.sections[10].x, selrect.y - surface_offset.y + obj.sections[10].y, selrect.w, selrect.h, 8, 1, 0)
            end
          end

          gfx.a=1
          f_Get_SSV(gui.color.white)
          gfx.rect(obj.sections[15].x,
                   obj.sections[15].y, 
                   obj.sections[15].w,
                   obj.sections[15].h, 1, 1)
          GUI_textC(gui,obj.sections[15],'SAVE STRIP',gui.color.black,-2)        

          if update_gfx then
            if lockh > 0 or lockw > 0 then
              UpdateLEdges()
            end
          end
          
          if ctl_select ~= nil then
            --gfx.dest = 1
            local w,h = gfx.getimgdim(1021)
            gfx.a = 0.5
            gfx.blit(1021,1,0,0,0,w,h,obj.sections[60].x,obj.sections[60].y)          
          end
        
        end

      end
      
      local xywh = {x = obj.sections[43].w-1,
                    y = obj.sections[43].y,
                    w = 1,
                    h = obj.sections[43].h}
      f_Get_SSV(gui.color.cbobg2)
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )

      GUI_DrawTopBar(gui,obj)

      if MS_Open > 0 then
        GUI_DrawMsg(gui, obj)
        
      elseif EB_Open > 0 then
        editbox_draw(gui, editbox)
      end
      
      if update_surfaceedge then
        UpdateEdges()
      end
      
      if settings_showbars and (update_gfx or update_surface) then
        GUI_DrawBars(gui, obj)
      end

      if show_settings then
        GUI_DrawSettings(gui, obj)
      end
      
      
      --[[if lockw > 0 or lockh > 0 then
        UpdateLEdges()
      end]]
 
    end
    
    gfx.dest = -1
    gfx.a = 1
    gfx.blit(1, 1, 0, 
      0,0, gfx1.main_w,gfx1.main_h,
      0,0, gfx1.main_w,gfx1.main_h, 0,0)
      
    update_gfx = false
    update_surface = false
    update_surfaceedge = false
    update_sidebar = false
    update_topbar = false
    update_ctlopts = false
    resize_display = false
    update_ctls = false
    update_bg = false
    update_settings = false
    
  end
  
  function GUI_DrawTopBar(gui, obj)
  
    gfx.a=1
    f_Get_SSV(gui.color.black)
    gfx.rect(0,
             obj.sections[11].y, 
             gfx1.main_w,
             obj.sections[11].h+2, 1, 1)

    if mode == 0 then

      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[11].x,
               obj.sections[11].y, 
               obj.sections[11].w,
               obj.sections[11].h, 1, 1)
      
      GUI_textC(gui,obj.sections[11],'LIVE MODE',gui.color.black,-2)

    else

      f_Get_SSV(gui.color.red)
      gfx.rect(obj.sections[11].x,
               obj.sections[11].y, 
               obj.sections[11].w,
               obj.sections[11].h, 1, 1)
    
      GUI_textC(gui,obj.sections[11],'EDIT MODE',gui.color.black,-2)
    
      gfx.a=1
      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[13].x,
               obj.sections[13].y, 
               obj.sections[13].w,
               obj.sections[13].h, 1, 1)
      GUI_textC(gui,obj.sections[13],submode_table[submode+1],gui.color.black,-2)        
    end
    f_Get_SSV(gui.color.black)
    gfx.rect(obj.sections[11].x+obj.sections[11].w-6,
             obj.sections[11].y,
             2,
             obj.sections[11].h,1)        
    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[11].x+obj.sections[11].w-4,
             obj.sections[11].y,
             4,
             obj.sections[11].h,1)        
    
    --[[local c = gui.color.black
    if mode == 0 then
      f_Get_SSV(gui.color.white)
    elseif settings_showgrid then
      f_Get_SSV(gui.color.white)
    else
      f_Get_SSV(gui.color.black)
      c = gui.color.white        
    end
    gfx.rect(obj.sections[16].x,
             obj.sections[16].y, 
             obj.sections[16].w,
             obj.sections[16].h, 1, 1)
    if mode ~= 0 then
      GUI_textC(gui,obj.sections[16],'GRID: '..settings_gridsize,c,-2)
    end]]    
    
    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[12].x,
             obj.sections[12].y, 
             obj.sections[12].w,
             obj.sections[12].h, 1, 1)
    
    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[18].x,
             obj.sections[18].y, 
             obj.sections[18].w,
             obj.sections[18].h, 1, 1)
    if mode == 0 then
      if show_editbar then
        GUI_textC(gui,obj.sections[18],'<',gui.color.black,-2)
      else
        GUI_textC(gui,obj.sections[18],'>',gui.color.black,-2)      
      end
    else
      GUI_textC(gui,obj.sections[18],'<>',gui.color.black,-2)
    end    
    
    local t
    for i = 0, 3 do
      local xywh = {x = obj.sections[20].x + i*(obj.sections[20].w/4),
                    y = obj.sections[20].y, 
                    w = obj.sections[20].w/4-2,
                    h = obj.sections[20].h}
      if i == 0 and lockx == false then 
        f_Get_SSV(gui.color.white)
        c = gui.color.black
        t = 'X'
      elseif i == 0 then
        f_Get_SSV(gui.color.black)
        c = gui.color.white
        t = 'X'
      elseif i == 1 and locky == false then         
        f_Get_SSV(gui.color.white)
        c = gui.color.black
        t = 'Y'
      elseif i == 1 then
        f_Get_SSV(gui.color.black)
        c = gui.color.white
        t = 'Y'
      elseif i == 2 then
        f_Get_SSV(gui.color.white)
        c = gui.color.black
        t = ''
      elseif i == 3 then
        f_Get_SSV(gui.color.white)
        c = gui.color.black        
        t = ''
      end
              
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1, 1)
      GUI_textC(gui,xywh,t,c,-2)
      if i == 2 then
        gfx.triangle(xywh.x+xywh.w/2,xywh.y+6,xywh.x+xywh.w/2-4,xywh.y+xywh.h-6,xywh.x+xywh.w/2+4,xywh.y+xywh.h-6,1)
      elseif i == 3 then
        gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-6,xywh.x+xywh.w/2-4,xywh.y+6,xywh.x+xywh.w/2+4,xywh.y+6,1)
      end
    end      
    
    if obj.sections[12].w > 0 then
      if infomsg ~= nil then
        GUI_textC(gui,obj.sections[12],infomsg,gui.color.black,-2)
        infomsg = nil        
      elseif tracks and tracks[track_select] then
        local trn = tracks[track_select].name
        if trn == '' then
          trn = '[unnamed track]'
        end
        GUI_textC_LIM(gui,obj.sections[12],'TRACK: ' .. tracks[track_select].tracknum+1 .. ' - '.. trn,gui.color.black,-2)
      end
    end  

    if obj.sections[17].x > obj.sections[20].x+obj.sections[20].w then
      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[17].x,
               obj.sections[17].y, 
               obj.sections[17].w,
               obj.sections[17].h, 1, 1)
      GUI_textC(gui,obj.sections[17],'SAVE',gui.color.black,-2)
    --end
        
    --if obj.sections[19].x > obj.sections[20].x+obj.sections[20].w then
      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[19].x,
               obj.sections[19].y, 
               obj.sections[19].w,
               obj.sections[19].h, 1, 1)
      GUI_textC(gui,obj.sections[19],'*',gui.color.black,-2)
    --end

    --if obj.sections[14].x > obj.sections[20].x+obj.sections[20].w then
    else
      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[21].x,
               obj.sections[21].y, 
               obj.sections[21].w,
               obj.sections[21].h, 1, 1)
      GUI_textC(gui,obj.sections[21],'...',gui.color.black,-2)
      f_Get_SSV(gui.color.black)
      gfx.rect(obj.sections[21].x-2,
               obj.sections[21].y, 
               2,
               obj.sections[21].h, 1, 1)
      
    end

    local c
    f_Get_SSV(gui.color.black)
    gfx.rect(obj.sections[14].x,
             obj.sections[14].y, 
             obj.sections[14].w,
             obj.sections[14].h, 1, 1)
    
    for i = 0, 3 do
      local xywh = {x = obj.sections[14].x+2 + i*(obj.sections[14].w/4),
                    y = obj.sections[14].y, 
                    w = obj.sections[14].w/4-2,
                    h = obj.sections[14].h}
      if page == i+1 then
        f_Get_SSV(gui.color.white)
        c = gui.color.black
      else
        f_Get_SSV(gui.color.black)
        c = gui.color.white
      end
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1, 1)
      GUI_textC(gui,xywh,i+1,c,-2)
    end
      
  end
  
  function GUI_DrawBars(gui, obj)
  
    local ww = gfx1.main_w - (plist_w+2)
    local bw = F_limit((obj.sections[10].w / surface_size.w),0,1)*(ww-4)
    local bx = F_limit(F_limit(((surface_offset.x) / surface_size.w),0,1)*(ww-4),0,ww-4-bw)

    local hh = gfx1.main_h - (butt_h+2)
    local bh = F_limit((obj.sections[10].h / surface_size.h),0,1)*(hh-4)
    local by = F_limit(F_limit(((surface_offset.y) / surface_size.h),0,1)*(hh-4),0,hh-4-bh)

    local xywh = {x = plist_w+2,
                  y = butt_h+2,
                  w = ww,
                  h = sb_size+2}
    f_Get_SSV(gui.color.black)
    gfx.a = 1  
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )

    local xywh = {x = (plist_w),
                  y = (butt_h+2),
                  w = sb_size+6,
                  h = hh}
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )

    local xywh = {x = (plist_w+2)+2 +bx,
                  y = butt_h+2,
                  w = bw,
                  h = sb_size}
    f_Get_SSV(gui.color.white)
    gfx.a = 1
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )

    local xywh = {x = (plist_w+4),
                  y = (butt_h+4) + by,
                  w = sb_size,
                  h = bh}
    f_Get_SSV(gui.color.white)
    gfx.a = 1
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )
  
  end
  
  function GUI_DrawSettings(gui, obj)
  
    f_Get_SSV('0 0 0')
    gfx.a = 1 
    gfx.rect(obj.sections[70].x,
             obj.sections[70].y, 
             obj.sections[70].w,
             obj.sections[70].h, 1)
    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[70].x,
             obj.sections[70].y, 
             obj.sections[70].w,
             obj.sections[70].h, 0)

    GUI_DrawTick(gui, 'Follow selected track', obj.sections[71], gui.color.white, settings_followselectedtrack)             
    GUI_DrawTick(gui, 'Auto centre controls', obj.sections[72], gui.color.white, settings_autocentrectls)             
    GUI_DrawTick(gui, 'Save all track fx with strip', obj.sections[73], gui.color.white, settings_saveallfxinstrip)
    GUI_DrawSliderH(gui, 'Control refresh rate', obj.sections[74], gui.color.black, gui.color.white, (1-(settings_updatefreq*10)))
    GUI_DrawTick(gui, 'Lock control window width', obj.sections[75], gui.color.white, lockx)
    GUI_DrawTick(gui, 'Lock control window height', obj.sections[76], gui.color.white, locky)
    GUI_DrawButton(gui, lockw, obj.sections[77], gui.color.white, gui.color.black, lockx)
    GUI_DrawButton(gui, lockh, obj.sections[78], gui.color.white, gui.color.black, locky)
    
    GUI_DrawTick(gui, 'Show grid / grid size', obj.sections[80], gui.color.white, settings_showgrid)
    GUI_DrawButton(gui, settings_gridsize, obj.sections[79], gui.color.white, gui.color.black, true)
               
  end
  
  function UpdateLEdges()

    local winw, winh = obj.sections[10].w , obj.sections[10].h
    if lockh > 0 then
      f_Get_SSV('0 0 0')
    
      local xywh = {x = obj.sections[10].x,
                    y = obj.sections[10].y,
                    w = obj.sections[10].w,
                    h = obj.sections[10].h}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )
      local xywh = {x = obj.sections[10].x,
                    y = obj.sections[10].y,
                    w = obj.sections[10].w,
                    h = obj.sections[10].h}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )
    
    
    end
        
  end
  
  function UpdateLEdges()

    f_Get_SSV('0 0 0')
    if lockw > 0 then

      local xx = plist_w+2
      
      if obj.sections[10].x > xx then
        local xywh = {x = xx,
                      y = obj.sections[10].y,
                      w = obj.sections[10].x - xx,
                      h = obj.sections[10].h}
        gfx.a = 1 
        gfx.rect(xywh.x,
                 xywh.y, 
                 xywh.w,
                 xywh.h, 1 )
        
        xx = obj.sections[10].x + obj.sections[10].w+1
        local xywh = {x = xx,
                      y = obj.sections[10].y,
                      w = gfx1.main_w - xx,
                      h = obj.sections[10].h}
        gfx.a = 1 
        gfx.rect(xywh.x,
                 xywh.y, 
                 xywh.w,
                 xywh.h, 1 )
        
      end
    
    end
    if lockh > 0 then
    
      local yy = butt_h+2
      
      if obj.sections[10].y > yy then
        local xywh = {x = obj.sections[10].x,
                      y = yy,
                      w = obj.sections[10].w,
                      h = obj.sections[10].y - yy}
        gfx.a = 1 
        gfx.rect(xywh.x,
                 xywh.y, 
                 xywh.w,
                 xywh.h, 1 )
        
        yy = obj.sections[10].y + obj.sections[10].h+1
        local xywh = {x = obj.sections[10].x,
                      y = yy,
                      w = obj.sections[10].w,
                      h = gfx1.main_h - yy}
        gfx.a = 1 
        gfx.rect(xywh.x,
                 xywh.y, 
                 xywh.w,
                 xywh.h, 1 )
        
      end
    
    end

  end
  
  function UpdateEdges()
  
    local winw, winh = obj.sections[10].w , obj.sections[10].h
    
    f_Get_SSV('0 0 0')
    if surface_offset.x < 0 then
      local xywh = {x = obj.sections[10].x,
                    y = obj.sections[10].y,
                    w = -surface_offset.x-1,
                    h = winh}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )
    end
    if surface_offset.y < 0 then
      local xywh = {x = obj.sections[10].x,
                    y = obj.sections[10].y,
                    w = winw,
                    h = -surface_offset.y-1}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )
    end
    if surface_offset.x > surface_size.w-winw then
      local xywh = {x = obj.sections[10].x+winw-(surface_offset.x - (surface_size.w-winw))-1,
                    y = obj.sections[10].y,
                    w = surface_offset.x - (surface_size.w-winw),
                    h = winh}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )    
    end
    if surface_offset.y > surface_size.h-winh then
      local xywh = {x = obj.sections[10].x,
                    y = obj.sections[10].y+winh-(surface_offset.y - (surface_size.h-winh))-1,
                    w = winw,
                    h = surface_offset.y - (surface_size.h-winh)}
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1 )    
    end
  
  end
  
  function GUI_DrawMsg(gui, obj)
  
    f_Get_SSV('0 0 0')
    gfx.a = 1 
    gfx.rect(obj.sections[61].x,
             obj.sections[61].y, 
             obj.sections[61].w,
             obj.sections[61].h, 1)
    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[61].x,
             obj.sections[61].y, 
             obj.sections[61].w,
             obj.sections[61].h, 0)
    gfx.rect(obj.sections[62].x,
             obj.sections[62].y, 
             obj.sections[62].w,
             obj.sections[62].h, 1)
    GUI_textC(gui,obj.sections[62],'OK',gui.color.black,-2)
    if msgbox then         
      GUI_textC(gui,obj.sections[63],nz(msgbox.text1,''),gui.color.white,-2)         
    end
    
  end
  
  ------------------------------------------------------------
  
  function Lokasenna_Window_At_Center (w, h)
    -- thanks to Lokasenna 
    -- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    
    local l, t, r, b = 0, 0, w, h    
    local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)    
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2    
    gfx.init("LBX Stripper", w, h, 0, x, y)  
  end

 -------------------------------------------------------------     
      
  function F_limit(val,min,max)
      if val == nil or min == nil or max == nil then return end
      local val_out = val
      if val < min then val_out = min end
      if val > max then val_out = max end
      return val_out
    end   
  ------------------------------------------------------------
  
  function MOUSE_sliderHBar(b)
    if mouse.mx > b.x-200 and mouse.mx < b.x+b.w+200
       and mouse.LB then
      local mx = mouse.mx - (b.x)
     return (mx) / (b.w)
    end 
  end
    
  function MOUSE_slider(b,yoff)
    if mouse.LB then
      if yoff == nil then yoff = 0 end
      local my = mouse.my - (b.y-200) + yoff
     return (my) / (b.h+400)
    end 
  end
  function MOUSE_sliderRB(b)
    if mouse.RB then
      local my = mouse.my - (b.y-200)
     return (my) / (b.h+400)
    end 
  end
  
  function MOUSE_surfaceX(b)
    if mouse.LB then
      local mx = mmx - mouse.mx
     return (mx)
    end 
  end

  function MOUSE_surfaceY(b)
    if mouse.LB then
      local my = mmy - mouse.my
     return (my)
    end 
  end
    
  function MOUSE_click(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.LB 
      and not mouse.last_LB then
     return true 
    end 
  end
  
  function MOUSE_click_RB(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h 
      and mouse.RB 
      and not mouse.last_RB then
     return true 
    end 
  end

  function MOUSE_over(b)
    if mouse.mx > b.x and mouse.mx < b.x+b.w
      and mouse.my > b.y and mouse.my < b.y+b.h then
     return true 
    end 
  end
      
  ------------------------------------------------------------
    
  function GetParamValue(tracknum,fxnum,paramnum)
    track = GetTrack(tracknum)
    return reaper.TrackFX_GetParamNormalized(track, fxnum, paramnum)
  end
  
  ------------------------------------------------------------
  
  function SetParam()
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      local val = strips[tracks[track_select].strip][page].controls[trackfxparam_select].val
      local track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
      local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
      strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
      reaper.TrackFX_SetParamNormalized(track, nz(fxnum,-1), param, 
                            val)
    end
      
  end
  
------------------------------------------------------------
  
  function SetParam2(force)
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      local val = strips[tracks[track_select].strip][page].controls[trackfxparam_select].val
      local track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
      local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
      strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
      if force and force == true then
        reaper.TrackFX_SetParamNormalized(track, nz(fxnum,-1), param, 
                              1-math.abs(val-0.1))      
      end
      reaper.TrackFX_SetParamNormalized(track, nz(fxnum,-1), param, 
                            val)
    end
      
  end
  
  ------------------------------------------------------------    

  function Lasso_Select()
  
    ctl_select = nil
    gfx3_select = nil

    local l = {l = lasso.l, r = lasso.r, t = lasso.t, b = lasso.b}
    if lasso.r < lasso.l then
      l.l = lasso.r
      l.r = lasso.l
    end
    if lasso.b < lasso.t then
      l.b = lasso.t
      l.t = lasso.b
    end

    if strips and strips[tracks[track_select].strip] then
      if #strips[tracks[track_select].strip][page].controls > 0 then
      
        for i = 1, #strips[tracks[track_select].strip][page].controls do
          local ctl 
          ctl = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x + obj.sections[10].x,
                     y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y + obj.sections[10].y,
                     w = strips[tracks[track_select].strip][page].controls[i].w,
                     h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}
          if ((l.l <= ctl.x and l.r >= ctl.x+ctl.w) or (l.l <= ctl.x+ctl.w and l.r >= ctl.x)) and ((l.t <= ctl.y and l.b >= ctl.y+ctl.h) or (l.t <= ctl.y+ctl.h and l.b >= ctl.y)) then 
            if ctl_select == nil then
              ctl_select = {} 
              ctl_select[1] = {ctl = i}
            else
              local cs = #ctl_select+1
              ctl_select[cs] = {}
              ctl_select[cs].ctl = i
              ctl_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[i].x
              ctl_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[i].y
            end
          end
        end
      end
    end
  end

  ------------------------------------------------------------    

  function DeleteSelectedCtls()
    local i
    if ctl_select then
      local cnt = #strips[tracks[track_select].strip][page].controls
      for i = 1, #ctl_select do
        strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl] = nil
      end
      local tbl = {}
      for i = 1, cnt do
        if strips[tracks[track_select].strip][page].controls[i] ~= nil then
          table.insert(tbl, strips[tracks[track_select].strip][page].controls[i])
        end
      end
      strips[tracks[track_select].strip][page].controls = tbl
      ctl_select = nil
    end  
    
    if gfx3_select then
      local cnt = #strips[tracks[track_select].strip][page].graphics
      for i = 1, #gfx3_select do
        strips[tracks[track_select].strip][page].graphics[gfx3_select[i].ctl] = nil
      end
      local tbl = {}
      for i = 1, cnt do
        if strips[tracks[track_select].strip][page].graphics[i] ~= nil then
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[i])
        end
      end
      strips[tracks[track_select].strip][page].graphics = tbl
      gfx3_select = nil
    end  

    if gfx2_select then
      local cnt = #strips[tracks[track_select].strip][page].graphics
      strips[tracks[track_select].strip][page].graphics[gfx2_select] = nil
      local tbl = {}
      for i = 1, cnt do
        if strips[tracks[track_select].strip][page].graphics[i] ~= nil then
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[i])
        end
      end
      strips[tracks[track_select].strip][page].graphics = tbl
      gfx2_select = nil
    end  

  end

  ------------------------------------------------------------    

  function EditCtlName()
  
    if strips and strips[tracks[track_select].strip] then
    
      local sizex,sizey = 400,200
      editbox={title = 'Please enter a name for the selected controls:',
        x=400, y=100, w=120, h=20, l=4, maxlen=20,
        fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
        txtcol=0x000000, curscol=0x000000,
        font=1, fontsz=14, caret=0, sel=0, cursstate=0,
        text="", 
        hasfocus=true
      }
      
      EB_Open = 2  
    end
    
  end

  function EditCtlName2(txt)

    for i = 1, #ctl_select do
      strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctlname_override = txt
    end
    
  end
  
  function SaveStrip()
  
    if strips and strips[tracks[track_select].strip] then
  
      local verify = true
      if strips[tracks[track_select].strip][page].controls and #strips[tracks[track_select].strip][page].controls > 0 then
      
        for i = 1, #strips[tracks[track_select].strip][page].controls do
          if strips[tracks[track_select].strip][page].controls[i].fxfound == false then
            verify = false
            break
          end
        end
        if not verify then
        
          OpenMsgBox(1, 'Please remove/reassign all missing plugin controls before saving.', 1)
          
        else
      
          local sizex,sizey = 400,200
          editbox={title = 'Please enter a filename for the strip:',
            x=400, y=100, w=120, h=20, l=4, maxlen=20,
            fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
            txtcol=0x000000, curscol=0x000000,
            font=1, fontsz=14, caret=0, sel=0, cursstate=0,
            text="", 
            hasfocus=true
          }
          
          EB_Open = 1  
        end
      else
        OpenMsgBox(1, 'No controls on strip.', 1)
      end
    else
      OpenMsgBox(1, 'No controls on strip.', 1)
    end
    
  end

  function SaveStrip2(fn)

    if fn and string.len(fn)>0 then
      local tr = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      local i, j
      local fxcnt = 1
      local fxtbl = {}
      local _, chunk = reaper.GetTrackStateChunk(tr,'',false)
      for i = 0, reaper.TrackFX_GetCount(tr)-1 do
        if settings_saveallfxinststrip then 
          local _, fxname = reaper.TrackFX_GetFXName(tr, i, '')
          fxtbl[i+1] = {fxname = string.match(fxname, '.*: (.*) %('),
                        fxchunk = GetChunkPresetData(chunk, i),
                        fxguid = convertguid(reaper.TrackFX_GetFXGUID(tr, i)),
                        fxenabled = reaper.TrackFX_GetEnabled(tr, i)
                        }
        else
          --check fx has controls in strip
          local instrip = false
          for j = 1, #strips[tracks[track_select].strip][page].controls do
            if reaper.TrackFX_GetFXGUID(tr, i) == strips[tracks[track_select].strip][page].controls[j].fxguid then
              instrip = true
              break
            end
          end
          if instrip then
            local _, fxname = reaper.TrackFX_GetFXName(tr, i, '')
            fxtbl[fxcnt] = {fxname = string.match(fxname, '.*: (.*) %('),
                            fxchunk = GetChunkPresetData(chunk, i),
                            fxguid = convertguid(reaper.TrackFX_GetFXGUID(tr, i)),
                            fxenabled = reaper.TrackFX_GetEnabled(tr, i)
                            }          
            fxcnt = fxcnt + 1
          end
        end
      end
    
      savestrip = {}
      savestrip.strip = strips[tracks[track_select].strip][page]
      savestrip.fx = fxtbl
    
      --Pickle doesn't like {} in strings (much) - remove before pickling
      for i = 1, #savestrip.strip.controls do
        savestrip.strip.controls[i].fxguid = convertguid(savestrip.strip.controls[i].fxguid)
      end
  
      local save_path=strips_path..strip_folders[stripfol_select].fn..'/'
      local fn=save_path..fn..".strip"
    
      local DELETE=true
      local file
      
      if reaper.file_exists(fn) then
      
      end
      
      if DELETE then
        file=io.open(fn,"w")
        local pickled_table=pickle(savestrip)
        file:write(pickled_table)
        file:close()
      end

      --reinstate {} after pickling
      for i = 1, #savestrip.strip.controls do
        savestrip.strip.controls[i].fxguid = '{'..savestrip.strip.controls[i].fxguid..'}'
      end

      OpenMsgBox(1,'Strip saved.',1)

    end
    PopulateStrips()
    
  end
  
  function LoadStrip(strip_select)
  
    local stripdata = nil
    local load_path=strips_path
    local fn=load_path..strip_folders[stripfol_select].fn..'/'..strip_files[strip_select].fn
    if reaper.file_exists(fn) then
    
      local file
      file=io.open(fn,"r")
      local content=file:read("*a")
      file:close()
      
      stripdata = unpickle(content)
    else
      OpenMsgBox(1,'File not found.',1)
    end
    return stripdata
  
  end
  
  function Strip_AddStrip(stripdata, x, y)
    if track_select == nil then return end
  
    local strip, i, j
    if tracks[track_select].strip == -1 then
      strip = #strips+1
      strips[strip] = {track = tracks[track_select],page=page,{}}
      for i = 1,4 do
        strips[strip][i] = {surface_x = 0,
                           surface_y = 0,     
                           controls = {},
                           graphics = {}}
      end
      tracks[track_select].strip = strip
    else
      strip = tracks[track_select].strip
    end
    
    local tr = GetTrack(strips[strip].track.tracknum)
    
    local fxcnt = reaper.TrackFX_GetCount(tr)
    local retfx
    --create new fx
    local missing = 0
    for i = 1, #stripdata.fx do
  
      retfx = reaper.TrackFX_AddByName(tr, stripdata.fx[i].fxname, 0, -1)

      if retfx ~= -1 then      
        --set guid in stripdata.strip
        nguid = reaper.TrackFX_GetFXGUID(tr, fxcnt+i-1+missing)
        stripdata.fx[i].nfxguid = nguid
      else
        stripdata.fx[i].nfxguid = ''
        missing = missing + 1
      end
      
      for j = 1, #stripdata.strip.controls do
        if stripdata.strip.controls[j].fxguid == stripdata.fx[i].fxguid then
          stripdata.strip.controls[j].fxguid = stripdata.fx[i].nfxguid
          if stripdata.fx[i].nfxguid == '' then
            stripdata.strip.controls[j].fxfound = false
            stripdata.strip.controls[j].fxnum = -1
          else
            stripdata.strip.controls[j].fxfound = true
            stripdata.strip.controls[j].fxnum = fxcnt+(i-1)-missing
          end
        end
      end
      if retfx ~= -1 then
        local fxen = nz(stripdata.fx[i].fxenabled, true)
        reaper.TrackFX_SetEnabled(tr, fxcnt+i-1-missing, fxen)
      end
    end
    
    local _, chunk = reaper.GetTrackStateChunk(tr,'',false)
    missing = 0
    --DBG(chunk)
    for i = 1, #stripdata.fx do
      if stripdata.fx[i].nfxguid ~= '' then
        chunk = ReplaceChunkPresetData(chunk, i-1+fxcnt-missing, stripdata.fx[i].fxchunk)
      else
        missing = missing + 1
      end
    end
    if chunk ~= nil then
      reaper.SetTrackStateChunk(tr, chunk, false)
    end
    
    time = math.abs(math.sin( -1 + (os.clock() % 2)))
    stripid = math.floor(time * 0xFFFFFF)
    
    for j = 1, #stripdata.strip.controls do
      stripdata.strip.controls[j].x = stripdata.strip.controls[j].x + offsetx + x + surface_offset.x     
      stripdata.strip.controls[j].y = stripdata.strip.controls[j].y + offsety + y + surface_offset.y
      stripdata.strip.controls[j].id = stripid
      
      local cc = #strips[strip][page].controls + 1
      strips[strip][page].controls[cc] = stripdata.strip.controls[j]
      strips[strip][page].controls[cc].xsc = stripdata.strip.controls[j].x + math.floor(stripdata.strip.controls[j].w/2 
                                                                            - stripdata.strip.controls[j].w*stripdata.strip.controls[j].scale/2)
      strips[strip][page].controls[cc].ysc = stripdata.strip.controls[j].y + math.floor(stripdata.strip.controls[j].ctl_info.cellh/2 
                                                                            - stripdata.strip.controls[j].ctl_info.cellh*stripdata.strip.controls[j].scale/2)
      strips[strip][page].controls[cc].wsc = stripdata.strip.controls[j].w*stripdata.strip.controls[j].scale
      strips[strip][page].controls[cc].hsc = stripdata.strip.controls[j].ctl_info.cellh*stripdata.strip.controls[j].scale
      
      --compatibility
      if strips[strip][page].controls[cc].maxdp == nil then strips[strip][page].controls[cc].maxdp = -1 end
    end
    
    local lctl = GetLeftControlInStrip(strips[strip][page].controls, stripid)
    local dx, dy = 0, 0
    if lctl ~= -1 then
      local nx, ny = round(strips[strip][page].controls[lctl].x/settings_gridsize)*settings_gridsize,
                     round(strips[strip][page].controls[lctl].y/settings_gridsize)*settings_gridsize   
      dx, dy = strips[strip][page].controls[lctl].x-nx,strips[strip][page].controls[lctl].y-ny
      for j = 1, #strips[strip][page].controls do
        if strips[strip][page].controls[j].id == stripid then
          strips[strip][page].controls[j].x = strips[strip][page].controls[j].x - dx
          strips[strip][page].controls[j].y = strips[strip][page].controls[j].y - dy
          strips[strip][page].controls[j].xsc = strips[strip][page].controls[j].xsc -dx
          strips[strip][page].controls[j].ysc = strips[strip][page].controls[j].ysc -dy
        end
      end
    end
    
    for j = 1, #stripdata.strip.graphics do
      if surface_size.limit then
        stripdata.strip.graphics[j].x = stripdata.strip.graphics[j].x + offsetx + x + surface_offset.x -dx
        stripdata.strip.graphics[j].y = stripdata.strip.graphics[j].y + offsety + y + surface_offset.y -dy
      else
        stripdata.strip.graphics[j].x = stripdata.strip.graphics[j].x + offsetx + x - surface_offset.x     
        stripdata.strip.graphics[j].y = stripdata.strip.graphics[j].y + offsety + y - surface_offset.y
      end
      stripdata.strip.graphics[j].id = stripid
      
      strips[strip][page].graphics[#strips[strip][page].graphics + 1] = stripdata.strip.graphics[j]    
    end
    
    PopulateTrackFX()
    return stripid
    
  end
  
  function GenStripPreview(gui, strip)
  
    if strip then
      
      local i,j
      image_count_add = image_count    
      local minx, miny, maxx, maxy = nil,nil,nil,nil 
      if #strip.graphics > 0 then
        for i = 1, #strip.graphics do
          if minx == nil then
            minx = strip.graphics[i].x
            miny = strip.graphics[i].y
            maxx = strip.graphics[i].x + strip.graphics[i].w
            maxy = strip.graphics[i].y + strip.graphics[i].h
          else
            minx = math.min(minx, strip.graphics[i].x)
            miny = math.min(miny, strip.graphics[i].y)
            maxx = math.max(maxx, strip.graphics[i].x + strip.graphics[i].w)
            maxy = math.max(maxy, strip.graphics[i].y + strip.graphics[i].h)
          end
          local fnd = false
          for j = 0, #graphics_files do
            if graphics_files[j].fn == strip.graphics[i].fn then
              if graphics_files[j].imageidx ~= nil then
                fnd = true
                strip.graphics[i].imageidx = graphics_files[j].imageidx
              else
                fnd = true
                image_count_add = image_count_add + 1
                gfx.loadimg(image_count_add, graphics_path..strip.graphics[i].fn)
                strip.graphics[i].imageidx = image_count_add
              end
              break
            end
          end
          if not fnd then
          end
        end
      end
      if #strip.controls > 0 then      
        for i = 1, #strip.controls do
          if minx == nil then
            minx = strip.controls[i].x
            miny = strip.controls[i].y
            maxx = strip.controls[i].x + strip.controls[i].w
            maxy = strip.controls[i].y + strip.controls[i].ctl_info.cellh
          else
            minx = math.min(minx, strip.controls[i].x)
            miny = math.min(miny, strip.controls[i].y)
            maxx = math.max(maxx, strip.controls[i].x + strip.controls[i].w)
            maxy = math.max(maxy, strip.controls[i].y + strip.controls[i].ctl_info.cellh)
          end
          local fnd = false
          for j = 1, #ctl_files do
            if ctl_files[j].fn == strip.controls[i].ctl_info.fn then
              if ctl_files[j].imageidx ~= nil then
                fnd = true
                strip.controls[i].ctl_info.imageidx = ctl_files[j].imageidx
                strip.controls[i].knob_select = j
              else
                fnd = true
                image_count_add = image_count_add + 1
                gfx.loadimg(image_count_add, controls_path..strip.controls[i].ctl_info.fn)
                strip.controls[i].ctl_info.imageidx = image_count_add
                strip.controls[i].knob_select = j
              end
              break
            end
          end
          if not fnd then
          end
        end
      end
      offsetx = -minx
      offsety = -miny
      
      gfx.dest = 1022
      gfx.setimgdim(1022,-1,-1)
      gfx.setimgdim(1022,maxx+offsetx,maxy+offsety)

      --draw gfx
      if #strip.graphics > 0 then
      
        for i = 1, #strip.graphics do
        
          local x = strip.graphics[i].x+offsetx 
          local y = strip.graphics[i].y+offsety
          local w = strip.graphics[i].w
          local h = strip.graphics[i].h
          local imageidx = strip.graphics[i].imageidx
          
          gfx.blit(imageidx,1,0, 0, 0, w, h, x, y)
      
        end
      end      
      
      --draw controls    
      if #strip.controls > 0 then
      
        for i = 1, #strip.controls do
        
          local scale = strip.controls[i].scale
          local x = strip.controls[i].x+offsetx 
          local y = strip.controls[i].y+offsety
          local w = strip.controls[i].w
          local h = strip.controls[i].ctl_info.cellh
          local gh = h
          local val = math.floor(100*strip.controls[i].val)
          local fxnum = strip.controls[i].fxnum
          local param = strip.controls[i].param
          local iidx = strip.controls[i].ctl_info.imageidx
          local spn = strip.controls[i].show_paramname
          local spv = strip.controls[i].show_paramval
          local ctlnmov = nz(strip.controls[i].ctlname_override,'')
          local tc = strip.controls[i].textcol
          local toff = strip.controls[i].textoff
          local tsze = nz(strip.controls[i].textsize,0)
          local frames = strip.controls[i].ctl_info.frames
          local ctltype = strip.controls[i].ctltype
          local found = strip.controls[i].fxfound
    
          local v2 = strip.controls[i].val
          local val2 = F_limit(round(frames*v2,0),0,frames-1)
          
          gfx.a = 1
          
          if ctltype == 3 then
            --invert button
            val2 = 1-val2
          end
          
          --load image
          gfx.blit(iidx,scale,0, 0, (val2)*gh, w, h, x + w/2-w*scale/2, y + h/2-h*scale/2)
          xywh = {x = x, y = y+(h/2)-toff, w = w, h = 10}
          if w > strip.controls[i].w/2 then
            local Disp_ParamV
            local Disp_Name
            if ctlnmov == '' then
              Disp_Name = strip.controls[i].param_info.paramname
            else
              Disp_Name = ctlnmov
            end
            Disp_ParamV = ''
            if spn then
              GUI_textC(gui,xywh, tostring(Disp_Name),tc,-4+tsze)
            end
          end
          
        end
          
      end
    
    end
    gfx.dest = 1
  
  end
    
  ------------------------------------------------------------    

  function CheckStripControls()

    if strips and tracks[track_select] and strips[tracks[track_select].strip] then
      local tr_found = false
      
      --Check track guid
      tr_found = CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip)
        
      if tr_found and strips and strips[tracks[track_select].strip] then
        local tr = GetTrack(strips[tracks[track_select].strip].track.tracknum)
        for p = 1, 4 do
        
          if #strips[tracks[track_select].strip][p].controls > 0 then
          
            for c = 1, #strips[tracks[track_select].strip][p].controls do
            
              if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr, nz(strips[tracks[track_select].strip][p].controls[c].fxnum,-1)) then
                --fx found
                strips[tracks[track_select].strip][p].controls[c].fxfound = true
              else
                --find fx by guid
                local fx_found = false
                for f = 0, reaper.TrackFX_GetCount(tr) do
                  if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr, f) then
                    fx_found = true
                    strips[tracks[track_select].strip][p].controls[c].fxnum = f
                    break
                  end
                end
                
                if not fx_found then
                  --find by name?
                                  
                end
                
                PopulateTrackFX()
                update_gfx = true
                
                if fx_found then
                  strips[tracks[track_select].strip][p].controls[c].fxfound = true
                else
                  --FX not found
                  strips[tracks[track_select].strip][p].controls[c].fxfound = false
                end
              end            
            end
          end
        end
      
      else
        --Track not found
      end  
    end
    
  end

  function CheckTrack(track, strip)
  
    local found = false
    local trx = GetTrack(track.tracknum)
    if trx then
      if track.guid == reaper.GetTrackGUID(trx) then
        return true
      else
        --Find track and update tracknum
        for i = 0, reaper.CountTracks(0) do
          local tr = GetTrack(i)
          if tr ~= nil then
            if strips[strip].track.guid == reaper.GetTrackGUID(tr) then
              --found
              found = true
              strips[strip].track.tracknum = i
              update_gfx = true
              break 
            end
          end
        end
        PopulateTracks()
      end
    else
      for i = 0, reaper.CountTracks(0) do
        local tr = GetTrack(i)
        if tr ~= nil then
          if strips[strip].track.guid == reaper.GetTrackGUID(tr) then
            --found
            found = true
            strips[strip].track.tracknum = i
            update_gfx = true
            break 
          end
        end
      end    
      PopulateTracks()    
    end
    return found
    
  end
  
  ------------------------------------------------------------    

  function testchunk(tr)
    _, statechunk = reaper.GetTrackStateChunk(tr,'',false)
    reaper.ClearConsole()
    DBG(statechunk)
    
    local fxidx = 1
    local r, s, e = GetChunkPresetData(statechunk,fxidx)
    DBG(s..'  '..e..'  ')
    DBG(r)
    local t = string.sub(statechunk,s,e)
    DBG(t)
  end
  
  function ReplaceChunkPresetData(trackchunk, fxidx, newdata)

    local ret, s, e = GetChunkPresetData(trackchunk, fxidx)
    local newchunk 
    if s ~= nil and e ~= nil then
      newchunk = string.sub(trackchunk,1,s-1)..newdata..string.sub(trackchunk,e+1)
    end
    return newchunk
    
  end
  
  ------------------------------------------------------------    

  function GetChunkPresetData(chunk, fxidx)
    if chunk == nil then return nil end
    
    local ret,i,x,xe = _,_,0,1
    _,x1 = string.find(chunk, '<FXCHAIN*\n')
    xe = x1
    for i = 0, fxidx do
      if xe ~= nil then
        local cont = true
        while cont == true do
          xs,x = string.find(string.sub(chunk, xe), '<')
          if x == nil then break end
          --look for JS or VST
          if string.upper(string.sub(chunk,xe+xs,xe+xs+2)) == 'VST' or string.upper(string.sub(chunk,xe+xs,xe+xs+1)) == 'JS' then
            cont = false
          end
          xe = xe + x
        end
      end
    end
    local s,e = nil, nil
    if x ~= nil and xe ~= nil then
      xe=xe-1
      s, e = string.find(string.sub(chunk,xe), '.->')
      s = s+xe
      e = e+xe-3 --not sure why is required - newline+blank space i guess
      ret = string.sub(chunk,s,e)
    else
      ret = nil
    end
    return ret, s, e
  
  end

  function GetLeftControlInStrip(controls, stripid)
  
    local minx,x = 2048,2048
    local lctl = -1
    for j = 1, #strips[tracks[track_select].strip][page].controls do
      if strips[tracks[track_select].strip][page].controls[j].id == stripid then
        local x = math.min(x,strips[tracks[track_select].strip][page].controls[j].x)
        if x < minx then
          minx = x
          lctl = j
        end
      end
    end
    return lctl
    
  end
  
  function SelectStripElements(stripid)
    --find left most
    local lctl = GetLeftControlInStrip(strips[tracks[track_select].strip][page].controls, stripid)
    
    if lctl ~= -1 then
      ctl_select = {}
      ctl_select[1] = {}
      ctl_select[1].ctl = lctl
    
      for j = 1, #strips[tracks[track_select].strip][page].controls do
        if strips[tracks[track_select].strip][page].controls[j].id == stripid and j ~= lctl then
          local cs = #ctl_select+1
          ctl_select[cs] = {}
          ctl_select[cs].ctl = j
          if cs ~= 1 then        
            ctl_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[j].x
            ctl_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[j].y
          end
        end
      end
      gfx3_select = {}
      for j = 1, #strips[tracks[track_select].strip][page].graphics do
        if strips[tracks[track_select].strip][page].graphics[j].id == stripid then
          local cs = #gfx3_select+1
          gfx3_select[cs] = {}
          gfx3_select[cs].ctl = j
          gfx3_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].graphics[j].x
          gfx3_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].graphics[j].y
        end
      end
    end
  end

  function AutoCentreCtls()
  
    if strips and tracks[track_select] and strips[tracks[track_select].strip] then
      local xywh = CalcCtlRect()
      if xywh then
        if surface_size.limit then
        else
          surface_offset.x = ((obj.sections[10].w + plist_w)/2 - xywh.w/2) - xywh.x 
          surface_offset.y = ((obj.sections[10].h + butt_h)/2 - xywh.h/2) - xywh.y 
        end
        strips[tracks[track_select].strip][page].surface_x = surface_offset.x
        strips[tracks[track_select].strip][page].surface_y = surface_offset.y
        update_gfx = true
      end
    end
  
  end
  
  function OpenMenu(str)
  
    local ret = gfx.showmenu(str)
    return ret
    
  end
  
  function OpenMsgBox(id, str, butt)
  
    MS_Open = id
    msgbox = {text1 = str, b = butt}
    update_gfx = true
    
  end
  
  function TopMenu()
  
    local mstr
    if mode == 0 then
      mstr = 'Toggle Sidebar||Lock X|Lock Y|Scroll Up|Scroll Down||Save Script State|Open Settings||Page 1|Page 2|Page 3|Page 4'
    else
      mstr = '#Toggle Sidebar||Lock X|Lock Y|Scroll Up|Scroll Down||Save Script State|Open Settings||Page 1|Page 2|Page 3|Page 4'
    end
    gfx.x, gfx.y = mouse.mx, mouse.my
    res = OpenMenu(mstr)
    if res ~= 0 then
      if res == 1 then
        ToggleSidebar()
      elseif res == 2 then
        LockX()
      elseif res == 3 then
        LockY()
      elseif res == 4 then
        ScrollUp()
      elseif res == 5 then
        ScrollDown()
      elseif res == 6 then
        SaveData()
        infomsg = "*** DATA SAVED ***"
        OpenMsgBox(1,'Data Saved.',1)
        update_gfx = true      
      elseif res == 7 then
        show_settings = not show_settings
        update_gfx = true
      elseif res >= 8 and res <= 11 then
        SetPage(res-7)
      end
      update_gfx = true
    end
    
  end
  
  function ToggleSidebar()
    
    if mode == 0 then
      show_editbar = not show_editbar
      if show_editbar then
        plist_w = oplist_w
      else
        plist_w = 0
      end
      force_resize = true
    end    
  
  end
  
  function LockX()
    lockx = not lockx
    if lockx then
      surface_offset.x = 0
    end
    obj = GetObjects()
  end
  
  function LockY()
    locky = not locky
    if locky then
      surface_offset.y = 0
    end
    obj = GetObjects()
  end
  
  function ScrollUp()
    if surface_offset.y > 0 then
      if lockh > 0 then
        surface_offset.y = surface_offset.y - lockh
      else
        surface_offset.y = surface_offset.y - math.floor(obj.sections[10].h/settings_gridsize)*settings_gridsize
      end
    end
  end
  
  function ScrollDown()
    if surface_offset.y < surface_size.h-obj.sections[10].h then
      if lockh > 0 then
        surface_offset.y = surface_offset.y + lockh
      else
        surface_offset.y = surface_offset.y + math.floor(obj.sections[10].h/settings_gridsize)*settings_gridsize
      end
    end
  end
  
  function SetPage(lpage)
    
    page = lpage
    ctl_select = nil
    gfx2_select = nil
    gfx3_select = nil
    
    if strips and tracks[track_select] and strips[tracks[track_select].strip] then
      strips[tracks[track_select].strip].page = page
      surface_offset.x = tonumber(strips[tracks[track_select].strip][page].surface_x)
      surface_offset.y = tonumber(strips[tracks[track_select].strip][page].surface_y)
    else
      surface_offset.x = 0
      surface_offset.y = 0       
    end
    
    if settings_autocentrectls then
      AutoCentreCtls()
    end
    update_gfx = true
    
  end
  
  ------------------------------------------------------------    

  function run()  

    local rt = reaper.time_precise()
    if PROJECTID ~= tonumber(GPES('projectid')) then
      INIT()
      LoadData()
    end
    
    if gfx.w ~= last_gfx_w or gfx.h ~= last_gfx_h or force_resize then
      local r = false
      --if gfx.w < 800 then gfx.w = 800 r = true end
      --if gfx.h < 450 then gfx.h = 450 r = true end
      if not r or gfx.dock(-1) > 0 then 
        gfx1.main_w = gfx.w
        gfx1.main_h = gfx.h
        win_w = gfx.w
        win_h = gfx.h
  
        last_gfx_w = gfx.w
        last_gfx_h = gfx.h
        
        obj = GetObjects()
        
        if settings_autocentrectls then
          AutoCentreCtls()
        end
        
        resize_display = true
        update_gfx = true
        --update_surface = true
        force_resize = false
        
        if surface_size.w < obj.sections[10].w then
          surface_offset.x = -math.floor((obj.sections[10].w - surface_size.w)/2)
        end
      end
    end
    
    local ct = reaper.CountTracks(0)
    if ct ~= otrkcnt then
      PopulateTracks()
      update_gfx = true
      otrkcnt = ct
    end    
    
    local gui = GetGUI_vars()
    GUI_draw(obj, gui)
    
    mouse.mx, mouse.my = gfx.mouse_x, gfx.mouse_y  
    mouse.LB = gfx.mouse_cap&1==1
    mouse.RB = gfx.mouse_cap&2==2
    mouse.ctrl = gfx.mouse_cap&4==4
    mouse.shift = gfx.mouse_cap&8==8
    mouse.alt = gfx.mouse_cap&16==16

    if settings_followselectedtrack then
      if track_select ~= nil or ct > 0 then
        if ct > 0 then
          if track_select == nil then track_select = -1 end
          local st = reaper.GetSelectedTrack(0,0)
          if st == nil then
            st = GetTrack(-1)
          end
          local tr = GetTrack(track_select)
          if st ~= nil and tr ~= nil then
            if reaper.GetTrackGUID(st) ~= reaper.GetTrackGUID(tr) then
              PopulateTracks()
              for i = -1, reaper.CountTracks(0) do
                tr = GetTrack(i)
                tracks[i].name = reaper.GetTrackState(tr)
                if tr ~= nil then
                  if reaper.GetTrackGUID(st) == reaper.GetTrackGUID(tr) then
                    if strips[tracks[track_select].strip] then
                      strips[tracks[track_select].strip].page = page
                    end
                    track_select = i
                    if strips and tracks[track_select] and strips[tracks[track_select].strip] then
                      page = strips[tracks[track_select].strip].page
                      surface_offset.x = strips[tracks[track_select].strip][page].surface_x
                      surface_offset.y = strips[tracks[track_select].strip][page].surface_y
                    else
                      page = 1
                      surface_offset.x = 0
                      surface_offset.y = 0
                    end
                    break
                  end
                end
              end
              CheckStripControls()          
              PopulateTrackFX()
              ctl_select = nil
              gfx2_select = nil
              gfx3_select = nil
              if settings_autocentrectls then
                AutoCentreCtls()
              end
              update_gfx = true
            end
          end 
        end
      end      
    end
    
    if rt >= time_nextupdate then
      local suf = settings_updatefreq
      if mode == 1 then suf = 0.2 end

      time_nextupdate = rt + suf
      if strips and tracks[track_select] and strips[tracks[track_select].strip] and #strips[tracks[track_select].strip][page].controls > 0 then
        --check track
        if CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip) then
          local tr = GetTrack(strips[tracks[track_select].strip].track.tracknum)
          if tr ~= nil then
            if strips and strips[tracks[track_select].strip] then
              for i = 1, #strips[tracks[track_select].strip][page].controls do
                --check fx
                local fxguid = reaper.TrackFX_GetFXGUID(tr, strips[tracks[track_select].strip][page].controls[i].fxnum)
                if strips[tracks[track_select].strip][page].controls[i].fxguid == fxguid then
                  local v = reaper.TrackFX_GetParamNormalized(tr,
                                                             strips[tracks[track_select].strip][page].controls[i].fxnum,
                                                             strips[tracks[track_select].strip][page].controls[i].param)
                  if strips[tracks[track_select].strip][page].controls[i].val ~= v then
                    strips[tracks[track_select].strip][page].controls[i].val = v
                    strips[tracks[track_select].strip][page].controls[i].dirty = true
                    if strips[tracks[track_select].strip][page].controls[i].param_info.paramname == 'Bypass' then
                      SetCtlEnabled(strips[tracks[track_select].strip][page].controls[i].fxnum) 
                    end                                                                                                           
                    update_ctls = true
                  end
                else
                  if strips[tracks[track_select].strip][page].controls[i].fxfound then
                    CheckStripControls()
                  end
                end
              end
            end
          end
        end
      end
    end
    
    if show_settings then
      --if MOUSE_click(obj.sections[19]) then
        --settings
      --  show_settings = false
      --  SaveSettings()
      --  update_gfx = true
      if mouse.LB and not mouse.last_LB and not MOUSE_click(obj.sections[70]) then
        show_settings = false
        SaveSettings()
        update_gfx = true      
      end
      
      if MOUSE_click(obj.sections[71]) then
        settings_followselectedtrack = not settings_followselectedtrack
        update_settings = true
      elseif MOUSE_click(obj.sections[72]) then
        settings_autocentrectls = not settings_autocentrectls
        update_settings = true
      elseif MOUSE_click(obj.sections[73]) then
        settings_saveallfxinstrip = not settings_saveallfxinstrip
        update_settings = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[74]) then
        mouse.context = 'updatefreq'
        oval = settings_updatefreq
      elseif mouse.context == nil and MOUSE_click(obj.sections[75]) then
        lockx = not lockx
        obj = GetObjects()
        update_gfx = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[76]) then
        locky = not locky
        obj = GetObjects()
        update_gfx = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[77]) then
        mouse.context = 'lockw'
        ctlpos = lockw
      elseif mouse.context == nil and MOUSE_click(obj.sections[78]) then
        mouse.context = 'lockh'
        ctlpos = lockh
      elseif mouse.context == nil and MOUSE_click(obj.sections[80]) then
        settings_showgrid = not settings_showgrid
        osg = settings_showgrid
        if settings_gridsize < 16 then
          settings_showgrid = false
        end
        update_gfx = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[79]) then
        mouse.context = 'gridslider'
        ctlpos = settings_gridsize
      end
      
      if mouse.context and mouse.context == 'updatefreq' then
        local val = F_limit(MOUSE_sliderHBar(obj.sections[74]),0,1)
        if val ~= nil then
          settings_updatefreq = (1-val)/10
          if oval ~= settings_updatefreq then
            update_settings = true                  
          end 
          oval = settings_updatefreq          
        end
      elseif mouse.context and mouse.context == 'lockw' then
        local val = F_limit(MOUSE_slider(obj.sections[77]),0,1)
        if val ~= nil then
          val = 1-val
          lockw = F_limit( math.floor((val*1000)/settings_gridsize)*settings_gridsize,64,1000)
          obj = GetObjects()
          update_gfx = true
        end
      elseif mouse.context and mouse.context == 'lockh' then
        local val = F_limit(MOUSE_slider(obj.sections[78]),0,1)
        if val ~= nil then
          val = 1-val
          lockh = F_limit( math.floor((val*1000)/settings_gridsize)*settings_gridsize,64,1000)
          obj = GetObjects()
          update_gfx = true
        end
      elseif mouse.context and mouse.context == 'gridslider' then
        local val = F_limit(MOUSE_slider(obj.sections[79]),0,1)
        if val ~= nil then
          val = 1-val
          settings_gridsize = F_limit(ctlpos + math.floor((val-0.5)*200),1,128)
          ogrid = settings_gridsize
          if settings_gridsize < 16 then
            settings_showgrid = false
          else
            settings_showgrid = nz(osg,true)
          end
          update_gfx = true
        end
      end
      
    elseif MS_Open > 0 then
    
      if MOUSE_click(obj.sections[62]) then
        --OK
        if MS_Open == 1 then
          msgbox = nil
        end
        MS_Open = 0
        update_gfx = true
      end
      
    elseif EB_Open > 0 then
      if gfx.mouse_cap&1 == 1 then
        if not mouse.down then
          OnMouseDown()      
          if mouse.uptime and os.clock()-mouse.uptime < 0.25 then 
            OnMouseDoubleClick()
          end
        elseif gfx.mouse_x ~= mouse.lx or gfx.mouse_y ~= mouse.ly then
          OnMouseMove() 
        end
      elseif mouse.down then 
        OnMouseUp() 
      end
      
      if MOUSE_click(obj.sections[6]) then
        --OK
        if EB_Open == 1 then
          SaveStrip2(editbox.text)
        elseif EB_Open == 2 then
          EditCtlName2(editbox.text)
        end
        EB_Open = 0
      
      elseif MOUSE_click(obj.sections[7]) then
        EB_Open = 0
      end
          
      local c=gfx.getchar()  
      if editbox.hasfocus then editbox_onchar(editbox, c) end  
      update_gfx = true
    else
    
    if (obj.sections[17].x <= obj.sections[20].x+obj.sections[20].w) and MOUSE_click(obj.sections[21]) then
    
      TopMenu()

    elseif MOUSE_click(obj.sections[14]) then
      --page
      local page = F_limit(math.ceil((mouse.mx-obj.sections[14].x)/(obj.sections[14].w/4)),1,4)
      SetPage(page)            
    
    elseif MOUSE_click(obj.sections[11]) then
      if mouse.mx > obj.sections[11].w-6 then
        mouse.context = 'dragsidebar'
        offx = 0
        --DBG(obj.sections[11].x-10 ..'  '..mouse.mx)
      else
        gfx3_select = nil
        gfx2_select = nil
        ctl_select = nil
        if mode == 0 then
          mode = 1
          PopulateTrackFX()
        else
          SaveData()
          mode = 0
        end
        update_gfx = true
      end
      
    elseif MOUSE_click(obj.sections[18]) then
      ToggleSidebar()
      if mode == 1 then
        mouse.context = 'dragsidebar'
        offx = mouse.mx-plist_w
      end
    
    --elseif MOUSE_click(obj.sections[12]) then
      --centre
    --  AutoCentreCtls()
    elseif (obj.sections[17].x > obj.sections[20].x+obj.sections[20].w) and MOUSE_click(obj.sections[19]) then
      --settings
      show_settings = not show_settings
      update_gfx = true

    elseif (obj.sections[17].x > obj.sections[20].x+obj.sections[20].w) and MOUSE_click(obj.sections[17]) then
      SaveData()
      infomsg = "*** DATA SAVED ***"
      OpenMsgBox(1,'Data Saved.',1)
      update_gfx = true
    
    elseif MOUSE_click(obj.sections[20]) then
      local butt = F_limit(math.ceil((mouse.mx-obj.sections[20].x)/(obj.sections[20].w/4)),1,4)
      if butt == 1 then
        LockX()
        
      elseif butt == 2 then
        LockY()
        
      elseif butt == 3 then
        ScrollUp()
        
      elseif butt == 4 then
        ScrollDown()
        
      end
      update_gfx = true
    end
    
    if mouse.context and mouse.context == 'dragsidebar' then
    
      plist_w = math.max(mouse.mx-offx,0)
      oplist_w = math.max(plist_w,100)
      if plist_w <= 4 then
        show_editbar = false
      else
        show_editbar = true
      end
      obj = GetObjects()
      resize_display = true
      update_gfx = true
    
    end
    
    if mode == 0 then
      
      if gfx.mouse_wheel ~= 0 then
        local v = gfx.mouse_wheel/120
        if MOUSE_over(obj.sections[43]) then
          tlist_offset = F_limit(tlist_offset - v, 0, #tracks+1)
          update_gfx = true
          gfx.mouse_wheel = 0
        end
      end
      
      if mouse.context == nil and (MOUSE_click(obj.sections[10]) or MOUSE_click_RB(obj.sections[10])) then
        if mouse.mx > obj.sections[10].x then
          if strips and tracks[track_select] and strips[tracks[track_select].strip] then
            for i = 1, #strips[tracks[track_select].strip][page].controls do

              ctlxywh = {x = strips[tracks[track_select].strip][page].controls[i].xsc - surface_offset.x +obj.sections[10].x, 
                         y = strips[tracks[track_select].strip][page].controls[i].ysc - surface_offset.y +obj.sections[10].y, 
                         w = strips[tracks[track_select].strip][page].controls[i].wsc, 
                         h = strips[tracks[track_select].strip][page].controls[i].hsc}
              if strips[tracks[track_select].strip][page].controls[i].fxfound then
                if MOUSE_click(ctlxywh) and not mouse.ctrl then
                  local ctltype = strips[tracks[track_select].strip][page].controls[i].ctltype
                  if ctltype == 1 then
                    --knob/slider
                    mouse.context = 'sliderctl'
                    --knobslider = 'ks'
                    ctlpos = strips[tracks[track_select].strip][page].controls[i].val
                    trackfxparam_select = i
                    mouse.slideoff = ctlxywh.y+ctlxywh.h/2 - mouse.my
                    oms = mouse.shift
                    
                  elseif ctltype == 2 or ctltype == 3 then
                    --button/button inverse
                    trackfxparam_select = i
                    if strips[tracks[track_select].strip][page].controls[i].val < 0.5 then
                      strips[tracks[track_select].strip][page].controls[i].val = 1
                    else
                      strips[tracks[track_select].strip][page].controls[i].val = 0
                    end
                    SetParam()
                    strips[tracks[track_select].strip][page].controls[i].dirty = true
                    if strips[tracks[track_select].strip][page].controls[i].param_info.paramname == 'Bypass' then
                      SetCtlEnabled(strips[tracks[track_select].strip][page].controls[i].fxnum) 
                    end
                    update_ctls = true
                  elseif ctltype == 4 then
                    --cycle
                  end
                  break
                  
                elseif MOUSE_click_RB(ctlxywh) then
                  local mstr = 'MIDI Learn|Modulation'
                  trackfxparam_select = i
                  SetParam2(true)
                  gfx.x, gfx.y = mouse.mx, mouse.my
                  res = OpenMenu(mstr)
                  if res ~= 0 then
                    if res == 1 then
                      reaper.Main_OnCommand(41144,0)
                    elseif res == 2 then
                      reaper.Main_OnCommand(41143,0)                  
                    end
                  end
                  break
                elseif MOUSE_click(ctlxywh) and mouse.ctrl then --make double_click?
                  --default val
                  trackfxparam_select = i
                  strips[tracks[track_select].strip][page].controls[i].val = strips[tracks[track_select].strip][page].controls[i].defval
                  SetParam()
                  strips[tracks[track_select].strip][page].controls[i].dirty = true
                  update_ctls = true
                  break
                end

              end
            end
          end
        end
      end

      if mouse.context and mouse.context == 'sliderctl' then
        local val = MOUSE_slider(ctlxywh,mouse.slideoff)
        --gfx.mouse_y = 0
        if val ~= nil then
          if oms ~= mouse.shift then
            oms = mouse.shift
            ctlpos = strips[tracks[track_select].strip][page].controls[trackfxparam_select].val
            mouse.slideoff = ctlxywh.y+ctlxywh.h/2 - mouse.my
          else
            if mouse.shift then
              val = ctlpos + ((0.5-val)*2)*0.1
            else
              val = ctlpos + (0.5-val)*2
            end
            if val < 0 then val = 0 end
            if val > 1 then val = 1 end
            if val ~= octlval then
              strips[tracks[track_select].strip][page].controls[trackfxparam_select].val = val
              SetParam()
              strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
              octlval = val
              update_ctls = true
            end
          end
        end
      end
      
      if MOUSE_click(obj.sections[43]) then
        local i = math.floor((mouse.my - obj.sections[43].y) / butt_h)-1
        if i == -1 then
          tlist_offset = tlist_offset - T_butt_cnt
          if tlist_offset < 0 then
            tlist_offset = 0
          end
          update_gfx = true
        elseif i >= T_butt_cnt then
          if tlist_offset + T_butt_cnt < #tracks then
            tlist_offset = tlist_offset + T_butt_cnt
          end
          update_gfx = true
        elseif tracks[i-1 + tlist_offset] then
          if strips[tracks[track_select].strip] then
            strips[tracks[track_select].strip].page = page
          end
          track_select = i-1 + tlist_offset
          
          if settings_followselectedtrack then
            --Select track
            local tr = GetTrack(track_select)
            tracks[track_select].name = reaper.GetTrackState(tr)
            
            if tr ~= nil then
              reaper.SetOnlyTrackSelected(tr)
            end
          end
          if strips and strips[tracks[track_select].strip] then
            page = strips[tracks[track_select].strip].page
            surface_offset.x = strips[tracks[track_select].strip][page].surface_x
            surface_offset.y = strips[tracks[track_select].strip][page].surface_y
          else
            page = 1
            surface_offset.x = 0
            surface_offset.y = 0 
          end
          CheckStripControls()
          if settings_autocentrectls then
            AutoCentreCtls()
          end                
          update_gfx = true 
        end
      end
    
    elseif mode == 1 then
      
      if ct == 0 then
        track_select = -1
        update_gfx = true
      end
    
      local tr = GetTrack(track_select)
      if tr then
        local fxc = reaper.TrackFX_GetCount(tr)
        if fxc ~= ofxcnt then
          PopulateTrackFX()
          update_gfx = true
        end
      end
    
      --[[if mouse.context == nil and MOUSE_click(obj.sections[16]) then 
        settings_showgrid = not settings_showgrid
        osg = settings_showgrid
        if settings_gridsize < 16 then
          settings_showgrid = false
        end
        update_gfx = true
      elseif mouse.context == nil and MOUSE_click_RB(obj.sections[16]) then 
        mouse.context = 'gridslider' 
        ctlpos = settings_gridsize
         
      elseif mouse.context and mouse.context == 'gridslider' then
        local val = F_limit(MOUSE_sliderRB(obj.sections[16]),0,1)
        if val ~= nil then
          val = 1-val
          settings_gridsize = F_limit(ctlpos + math.floor((val-0.5)*200),1,120)
          ogrid = settings_gridsize
          if settings_gridsize < 16 then
            settings_showgrid = false
          else
            settings_showgrid = nz(osg,true)
          end
          update_gfx = true
        end
      end]]
            
      if mouse.shift then
        settings_gridsize = 1
      else
        settings_gridsize = ogrid      
      end

      if strips and tracks[track_select] and strips[tracks[track_select].strip] and #strips[tracks[track_select].strip][page].controls > 0 then
        CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip)
      end
            
      if submode == 0 then
        
        if gfx.mouse_wheel ~= 0 then
          local v = gfx.mouse_wheel/120
          if MOUSE_over(obj.sections[41]) then
            flist_offset = F_limit(flist_offset - v, 0, #trackfx)
            update_gfx = true
            gfx.mouse_wheel = 0
          end
          if MOUSE_over(obj.sections[42]) then
            plist_offset = F_limit(plist_offset - v, 0, #trackfxparams)
            update_gfx = true
            gfx.mouse_wheel = 0
          end
          if MOUSE_over(obj.sections[45]) then
            local xywh = {x = obj.sections[45].x, y = obj.sections[45].y, w = obj.sections[45].w, h = 150}
            if MOUSE_over(xywh) then
              knob_select = (knob_select - v) % #ctl_files
              update_gfx = true
              gfx.mouse_wheel = 0
            end
            if MOUSE_over(obj.sections[56]) then
              textoff_select = textoff_select + v*2
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textoff = textoff_select
              end            
              update_gfx = true
              gfx.mouse_wheel = 0
            end
            if MOUSE_over(obj.sections[65]) then
              textoffval_select = textoffval_select + v*2
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textoffval = textoffval_select
              end            
              update_gfx = true
              gfx.mouse_wheel = 0
            end
            if MOUSE_over(obj.sections[58]) then
              textsize_select = F_limit(textsize_select + v,-2,35)
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textsize = textsize_select
              end            
              update_gfx = true
              gfx.mouse_wheel = 0
            end

            if MOUSE_over(obj.sections[57]) then
              defval_select = F_limit(defval_select + v/200,0,1)
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].val = defval_select
                trackfxparam_select = ctl_select[i].ctl
                SetParam()
              end            
              update_gfx = true
              gfx.mouse_wheel = 0
            end
          end
        end
          
        if ctl_select ~= nil and (MOUSE_click(obj.sections[45]) or MOUSE_click_RB(obj.sections[45])) then
          
          --CONTROL OPTIONS
          
          if mouse.LB and mouse.my > obj.sections[45].y and mouse.my < obj.sections[45].y+150 then
          
            knob_select = knob_select + 1
            if knob_select > #ctl_files then
              knob_select = 0
            end
            update_gfx = true
          
          elseif mouse.RB and mouse.my > obj.sections[45].y and mouse.my < obj.sections[45].y+150 then

            knob_select = knob_select - 1
            if knob_select < 0 then
              knob_select = #ctl_files
            end
            update_gfx = true
          
          end

          if MOUSE_click(obj.sections[66]) then
          
            maxdp_select = F_limit(maxdp_select + 1, -1, 3)
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].maxdp = maxdp_select
            end            
            update_gfx = true
          
          elseif MOUSE_click_RB(obj.sections[66]) then

            maxdp_select = F_limit(maxdp_select - 1, -1, 3)
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].maxdp = maxdp_select
            end            
            update_gfx = true
          
          end

          if MOUSE_click(obj.sections[52]) then
            show_paramname = not show_paramname
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].show_paramname = show_paramname
            end            
            update_gfx = true
          end

          if MOUSE_click(obj.sections[53]) then
            show_paramval = not show_paramval
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].show_paramval = show_paramval
            end            
            update_gfx = true
          end

          if MOUSE_click(obj.sections[54]) then
            local retval, c = reaper.GR_SelectColor(_,ConvertColorString(textcol_select))
            if retval ~= 0 then
              textcol_select = ConvertColor(c)
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textcol = textcol_select
              end
              update_gfx = true
            end
          end

          if MOUSE_click(obj.sections[55]) then
            ctltype_select = ctltype_select + 1
            if ctltype_select > #ctltype_table then ctltype_select = 1 end
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctltype = ctltype_select
            end
            update_gfx = true
          end

          if MOUSE_click(obj.sections[59]) then
            if ctl_select and #ctl_select > 0 then
              EditCtlName()
              update_gfx = true
            end
          end
        
          if MOUSE_click(obj.sections[51]) then
            --apply
            if ctl_files[knob_select].imageidx == nil then  
              image_count = image_count + 1
              gfx.loadimg(image_count, controls_path..ctl_files[knob_select].fn)
              ctl_files[knob_select].imageidx = image_count
            end
            local w, _ = gfx.getimgdim(ctl_files[knob_select].imageidx)
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].knob_select = knob_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.fn = ctl_files[knob_select].fn
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.imageidx = ctl_files[knob_select].imageidx
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.frames = ctl_files[knob_select].frames
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w = w
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh = ctl_files[knob_select].cellh
              
              local scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x
                                                                                         + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w/2
                                                                                         - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale)/2)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
                                                                                         + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh/2
                                                                                         - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale)/2)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].wsc = w*scale
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].hsc = ctl_files[knob_select].cellh*scale
            end
            update_gfx = true
          end
          
          if mouse.context == nil and MOUSE_click(obj.sections[50]) then mouse.context = 'scaleslider' 
          elseif mouse.context == nil and MOUSE_click(obj.sections[56]) then mouse.context = 'offsetslider' 
          elseif mouse.context == nil and MOUSE_click(obj.sections[65]) then mouse.context = 'valoffsetslider' 
          elseif mouse.context == nil and MOUSE_click(obj.sections[57]) then omx = -1 ctlpos = defval_select mouse.context = 'defvalslider' 
          elseif mouse.context == nil and MOUSE_click(obj.sections[58]) then mouse.context = 'textsizeslider' end
        
        elseif mouse.mx > obj.sections[10].x then
        
          --SURFACE
        
          if mouse.context == nil and MOUSE_click(obj.sections[10]) then
            if strips and tracks[track_select] and strips[tracks[track_select].strip] then
              for i = 1, #strips[tracks[track_select].strip][page].controls do
              
                local xywh
                xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                        y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                        w = strips[tracks[track_select].strip][page].controls[i].w, 
                        h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}
                if MOUSE_click(xywh) then
                  mouse.context = 'dragctl'
                  dragctl = 'dragctl'
                  
                  local found = false
                  local j
                  if ctl_select ~= nil then
                    for j = 1, #ctl_select do
                      if tonumber(ctl_select[j].ctl) == tonumber(i) then
                        found = true
                        break
                      end
                    end
                  end
                  
                  if mouse.alt then
                    local stripid = strips[tracks[track_select].strip][page].controls[i].id
                    if stripid ~= nil then
                      SelectStripElements(stripid)
                    else
                      if ctl_select == nil then
                        ctl_select = {}
                        ctl_select[1] = {ctl = i}
                      else
                        local cs = #ctl_select+1
                        ctl_select[cs] = {}
                        ctl_select[cs].ctl = i                      
                        ctl_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[i].x
                        ctl_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[i].y
                      end
                    end
    
                  elseif mouse.ctrl and ctl_select ~= nil and found == false then
                    local cs = #ctl_select+1
                    ctl_select[cs] = {}
                    ctl_select[cs].ctl = i
                    ctl_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[i].x
                    ctl_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[i].y
                  elseif ctl_select == nil or found == false then
                    ctl_select = {} 
                    ctl_select[1] = {ctl = i}
                  end
                                    
                  ctltype_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctltype
                  knob_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].knob_select
                  scale_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
                  textcol_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textcol
                  show_paramname = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramname
                  show_paramval = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramval
                  textoff_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textoff
                  textsize_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textsize
                  defval_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].defval
                  maxdp_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].maxdp,-1)                  
                  
                  dragoff = {x = mouse.mx - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w - surface_offset.x,
                             y = mouse.my - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh - surface_offset.y}
                             
                  update_gfx = true
                  break
                end
              end
            end
          elseif mouse.context == nil and MOUSE_click_RB(obj.sections[10]) then
            mouse.context = 'draglasso'
            lasso = {l = mouse.mx, t = mouse.my, r = mouse.mx+5, b = mouse.my+5}
          end
        end
        
        if mouse.context and mouse.context == 'scaleslider' then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[50]),0,1)
          if val ~= nil then
            scale_select = val*0.5 + 0.5
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale = scale_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x
                                                                                         + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w/2
                                                                                         - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale_select)/2)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
                                                                                         + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh/2
                                                                                         - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale_select)/2)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].wsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].hsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale_select
            end            
            update_gfx = true
            --update_ctls = true
          end
        end

        if mouse.context and mouse.context == 'offsetslider' then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[56]),0,1)
          if val ~= nil then
            textoff_select = val*300 - 150
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textoff = textoff_select
              --strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dirty = true
            end            
            update_gfx = true
          end
        end

        if mouse.context and mouse.context == 'valoffsetslider' then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[65]),0,1)
          if val ~= nil then
            textoffval_select = val*100 - 50
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textoffval = textoffval_select
            end            
            update_gfx = true
          end
        end

        if mouse.context and mouse.context == 'textsizeslider' then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[58]),0,1)
          if val ~= nil then
            textsize_select = (val*35)-2
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textsize = textsize_select
            end            
            update_gfx = true
          end
        end

        if mouse.context and mouse.context == 'defvalslider' then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[57]),0,1)
          local upd = false
          if mouse.ctrl then
            if mouse.mx ~= omx then
              if mouse.mx > omx then val = 0.002 else val = -0.002 end
              omx = mouse.mx
              val = F_limit(defval_select+val, 0, 1)
              upd = true
            end
          elseif val ~= nil then
            if mouse.shift then val = round(val*4,0)/4 end
            upd = true            
            val = F_limit(val, 0, 1)
          end
          if val ~= octlval and upd then
            defval_select = val
            octlval = val
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].val = defval_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval = defval_select
              trackfxparam_select = ctl_select[i].ctl
              SetParam()
            end
            update_ctls = true
          end
        end
            
        if mouse.context and mouse.context == 'dragctl' then
          if math.floor(mouse.mx/settings_gridsize) ~= math.floor(mouse.last_x/settings_gridsize) or math.floor(mouse.my/settings_gridsize) ~= math.floor(mouse.last_y/settings_gridsize) then
            local i
            local scale = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
            local zx, zy = 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w, 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh
            --strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].dirty = true
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x = math.floor((mouse.mx-zx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y = math.floor((mouse.my-zy - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x
                                                                                       + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w/2
                                                                                       - (strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w*scale)/2)
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y
                                                                                       + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh/2
                                                                                       - (strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh*scale)/2)
            if #ctl_select > 1 then
              for i = 2, #ctl_select do
                scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
                --strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dirty = true
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x = math.floor((mouse.mx-zx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize 
                                                                                   - ctl_select[i].relx
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y = math.floor((mouse.my-zy - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
                                                                                   - ctl_select[i].rely
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x
                                                                                           + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w/2
                                                                                           - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale)/2)
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
                                                                                           + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh/2
                                                                                           - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale)/2)
              end
            end
            if gfx3_select and #gfx3_select > 0 then
              --update_gfx = true
              for i = 1, #gfx3_select do
                strips[tracks[track_select].strip][page].graphics[gfx3_select[i].ctl].x = math.floor((mouse.mx-zx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize 
                                                                                   - gfx3_select[i].relx
                strips[tracks[track_select].strip][page].graphics[gfx3_select[i].ctl].y = math.floor((mouse.my-zy - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
                                                                                   - gfx3_select[i].rely
              end            
            end
            --update_ctls = true
            update_gfx = true
          end
        elseif dragctl ~= nil then
          dragctl = nil
          if MOUSE_over(obj.sections[60]) then
            --delete
            DeleteSelectedCtls()
            update_gfx = true
          end
        end      
  
        if mouse.context and mouse.context == 'draglasso' then
          if (mouse.mx ~= mouse.last_x or mouse.my ~= mouse.last_y) then
            lasso.r = mouse.mx
            lasso.b = mouse.my
            Lasso_Select()
            if ctl_select ~= nil then
              ctltype_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctltype
              knob_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].knob_select
              scale_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
              textcol_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textcol
              show_paramname = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramname
              show_paramval = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramval
              textoff_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textoff
              textsize_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textsize
              defval_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].defval
              maxdp_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].maxdp,-1)                  
            end
            update_ctls = true
          end
        elseif lasso ~= nil then
          --Dropped
          if lasso.l == mouse.mx and lasso.t == mouse.my then
            if ctl_select ~= nil then
              local mstr = 'Duplicate'
              gfx.x, gfx.y = mouse.mx, mouse.my
              local res = OpenMenu(mstr)
              if res == 1 then
                local c1 = #strips[tracks[track_select].strip][page].controls+1
                local dx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - (mouse.mx+surface_offset.x-obj.sections[10].x) 
                local dy = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - (mouse.my+surface_offset.y-obj.sections[10].y)
                for i = 1, #ctl_select do
                  local cc = c1+i-1
                  strips[tracks[track_select].strip][page].controls[cc]=GetControlTable(ctl_select[i].ctl)
                  --table.insert(strips[tracks[track_select].strip][page].controls[cc], strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl])
                  strips[tracks[track_select].strip][page].controls[cc].x = strips[tracks[track_select].strip][page].controls[cc].x - dx
                  strips[tracks[track_select].strip][page].controls[cc].y = strips[tracks[track_select].strip][page].controls[cc].y - dy
                  strips[tracks[track_select].strip][page].controls[cc].xsc = strips[tracks[track_select].strip][page].controls[cc].xsc - dx
                  strips[tracks[track_select].strip][page].controls[cc].ysc = strips[tracks[track_select].strip][page].controls[cc].ysc - dy
                  strips[tracks[track_select].strip][page].controls[cc].id = nil
                end
                ctl_select = nil
                for i = c1, #strips[tracks[track_select].strip][page].controls do
                  if ctl_select == nil then
                    ctl_select = {}
                    ctl_select[1] = {ctl = i}
                  else
                    local cs = #ctl_select+1
                    ctl_select[cs] = {}
                    ctl_select[cs].ctl = i                      
                    ctl_select[cs].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[i].x
                    ctl_select[cs].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[i].y
                  end
                end                
                update_gfx = true
              end
            
            end
          
          end
          
          lasso = nil
          update_ctls = true
        end
      
        if MOUSE_click(obj.sections[41]) then
          --DBG(mouse.my..'  '..obj.sections[41].y..'  '..butt_h)
          local i = math.floor((mouse.my - obj.sections[41].y) / butt_h)-2
          --DBG(i..'  '..F_butt_cnt)
          if i == -1 then
            flist_offset = flist_offset - F_butt_cnt
            if flist_offset < 0 then
              flist_offset = 0
            end
            update_gfx = true
          elseif i >= F_butt_cnt then
            if flist_offset + F_butt_cnt < #trackfx then
              flist_offset = flist_offset + F_butt_cnt-1
            end
            update_gfx = true
          elseif trackfx[i + flist_offset] then
            trackfx_select = i + flist_offset
            PopulateTrackFXParams()
            update_gfx = true
          end
        elseif MOUSE_click_RB(obj.sections[41]) then
          local i = math.floor((mouse.my - obj.sections[41].y) / butt_h)-1
          if i == -1 then
          elseif i >= F_butt_cnt-1 then
          elseif trackfx[i + flist_offset] then
            local track = GetTrack(tracks[track_select].tracknum)
            if not reaper.TrackFX_GetOpen(track, i + flist_offset) then
              reaper.TrackFX_Show(track, i + flist_offset, 3)
            end
          end        
        end
      
        if MOUSE_click(obj.sections[42]) then
          local i = math.floor((mouse.my - obj.sections[42].y) / butt_h)-2
          --DBG(i)
          if i == -1 then
            plist_offset = plist_offset - P_butt_cnt
            if plist_offset < 0 then
              plist_offset = 0
            end
            update_gfx = true
          elseif i >= P_butt_cnt then
            if plist_offset + P_butt_cnt < #trackfxparams then
              plist_offset = plist_offset + P_butt_cnt
            end
            update_gfx = true
          elseif trackfxparams[i + plist_offset] then
            trackfxparam_select = i + plist_offset
            if mouse.ctrl then
              if tfxp_sel == nil then
                tfxp_sel = {}
                tfxp_sel[i + plist_offset] = true
              elseif tfxp_sel[i + plist_offset] then
                --remove
                tfxp_sel[i + plist_offset] = nil
              else
                tfxp_sel[i + plist_offset] = true
              end
            elseif tfxp_sel and tfxp_sel[i + plist_offset] then
              --do nothing but drag
            else
              tfxp_sel = {}
              tfxp_sel[i + plist_offset] = true            
            end
            ctl_select = nil
            update_gfx = true

            if ctl_files[knob_select].imageidx ~= nil then
              local w,_ = gfx.getimgdim(ctl_files[knob_select].imageidx)
              local h = ctl_files[knob_select].cellh
              if w == 0 or h == 0 then
                ksel_size = {w = 50, h = 50}
              else
               ksel_size = {w = w/2, h = h/2}
             end
            else 
              ksel_size = {w = 50, h = 50}
            end
            mouse.context = 'dragparam'
          end
        end
        
        if mouse.context and mouse.context == 'dragparam' then
          dragparam = {x = mouse.mx-ksel_size.w, y = mouse.my-ksel_size.h}
          reass_param = nil
          if tracks[track_select] and tracks[track_select].strip ~= -1 then
            for i = 1, #strips[tracks[track_select].strip][page].controls do
            
              local xywh 
              if surface_size.limit then
                xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                        y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                        w = strips[tracks[track_select].strip][page].controls[i].w, 
                        h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}    
              else
                xywh = {x = strips[tracks[track_select].strip][page].controls[i].x + surface_offset.x, 
                        y = strips[tracks[track_select].strip][page].controls[i].y + surface_offset.y, 
                        w = strips[tracks[track_select].strip][page].controls[i].w, 
                        h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}
              end
              if MOUSE_over(xywh) then
                reass_param = i
                break
              end
            end
          end
                    
          update_gfx = true
        elseif dragparam ~= nil then
          --Dropped
          if reass_param == nil then
            if dragparam.x+ksel_size.w > obj.sections[10].x and dragparam.x+ksel_size.w < obj.sections[10].x+obj.sections[10].w and dragparam.y+ksel_size.h > obj.sections[10].y and dragparam.y+ksel_size.h < obj.sections[10].y+obj.sections[10].h then
              local i
              local cnt = 0
              local dpx, dpy = dragparam.x, dragparam.y
              for i = 0, #trackfxparams do
                if tfxp_sel[i] then
                  trackfxparam_select = i
                  Strip_AddParam()
                  cnt = cnt + 1
                  dragparam.x = math.floor(dpx + ((ksel_size.w*2+settings_gridsize) * (cnt % 8)))
                  dragparam.y = math.floor(dpy + (ksel_size.h*2+(2*settings_gridsize)) * math.floor(cnt/8))
                end
              end
              tfxp_sel = nil
              
            end
          else
            if dragparam.x+ksel_size.w > obj.sections[10].x and dragparam.x+ksel_size.w < obj.sections[10].x+obj.sections[10].w and dragparam.y+ksel_size.h > obj.sections[10].y and dragparam.y+ksel_size.h < obj.sections[10].y+obj.sections[10].h then
            
              local i
              local cnt = 0
              for i = 1, #trackfxparams do
                if tfxp_sel[i] then
                  cnt = cnt + 1
                end
              end
              if cnt <= 1 then
                strips[tracks[track_select].strip][page].controls[reass_param].fxname=trackfx[trackfx_select].name
                strips[tracks[track_select].strip][page].controls[reass_param].fxguid=trackfx[trackfx_select].guid
                strips[tracks[track_select].strip][page].controls[reass_param].fxnum=trackfx[trackfx_select].fxnum
                strips[tracks[track_select].strip][page].controls[reass_param].fxfound = true
                strips[tracks[track_select].strip][page].controls[reass_param].param = trackfxparam_select
                strips[tracks[track_select].strip][page].controls[reass_param].param_info = trackfxparams[trackfxparam_select]
                strips[tracks[track_select].strip][page].controls[reass_param].val = GetParamValue(tracks[track_select].tracknum,
                                                                                                   trackfx[trackfx_select].fxnum,
                                                                                                   trackfxparam_select)
                strips[tracks[track_select].strip][page].controls[reass_param].defval = GetParamValue(tracks[track_select].tracknum,
                                                                                                   trackfx[trackfx_select].fxnum,
                                                                                                   trackfxparam_select)
              else
                OpenMsgBox(1, 'You cannot reassign multiple controls at once.', 1)
              end
              tfxp_sel = nil
            end
          end
          
          reass_param = nil
          dragparam = nil
          update_gfx = true
        end
      
        if ctl_select ~= nil then
          show_ctloptions = true
        else
          show_ctloptions = false
        end
        
      elseif submode == 1 then

        if gfx.mouse_wheel ~= 0 then
          local v = gfx.mouse_wheel/120
          if MOUSE_over(obj.sections[44]) then
            glist_offset = F_limit(glist_offset - v, 0, #graphics_files)
            update_gfx = true
            gfx.mouse_wheel = 0
          end
        end
      
        if MOUSE_click(obj.sections[44]) then
          local i = math.floor((mouse.my - obj.sections[44].y) / butt_h)-1
          
          if i == -1 then
            glist_offset = glist_offset - G_butt_cnt
            if glist_offset < 0 then
              glist_offset = 0
            end
            update_gfx = true
          elseif i >= G_butt_cnt then
            if glist_offset + G_butt_cnt < #graphics_files then
              glist_offset = glist_offset + G_butt_cnt
            end
            update_gfx = true
          elseif graphics_files[i + glist_offset] then
            gfx_select = i + glist_offset
            
            --load temp image
            gfx.loadimg(1023,graphics_path..graphics_files[gfx_select].fn)
            
            update_gfx = true
            mouse.context = 'draggfx'
          end
          
        end
        
        if mouse.context and mouse.context == 'draggfx' then
          draggfx = {x = mouse.mx - 50, y = mouse.my - 50}
          update_gfx = true
        elseif draggfx ~= nil then
          --Dropped
          if draggfx.x+50 > obj.sections[10].x and draggfx.x+50 < obj.sections[10].w and draggfx.y+50 > obj.sections[10].y and draggfx.y+50 < obj.sections[10].h then
            Strip_AddGFX()
          end
          
          draggfx = nil
          update_gfx = true
        end
      
        if strips and tracks[track_select] and strips[tracks[track_select].strip] then
          for i = 1, #strips[tracks[track_select].strip][page].graphics do
            local xywh
            xywh = {x = strips[tracks[track_select].strip][page].graphics[i].x - surface_offset.x + obj.sections[10].x, 
                    y = strips[tracks[track_select].strip][page].graphics[i].y - surface_offset.y + obj.sections[10].y, 
                    w = strips[tracks[track_select].strip][page].graphics[i].w, 
                    h = strips[tracks[track_select].strip][page].graphics[i].h}
            if MOUSE_click(xywh) then
              mouse.context = 'draggfx2'
              gfx2_select = i              
              draggfx2 = 'draggfx'
              dragoff = {x = mouse.mx - strips[tracks[track_select].strip][page].graphics[gfx2_select].x - surface_offset.x,
                         y = mouse.my - strips[tracks[track_select].strip][page].graphics[gfx2_select].y - surface_offset.y}
              update_gfx = true
            end
          end
        end
          
        if mouse.context and mouse.context == 'draggfx2' then
          if math.floor(mouse.mx/settings_gridsize) ~= math.floor(mouse.last_x/settings_gridsize) or math.floor(mouse.my/settings_gridsize) ~= math.floor(mouse.last_y/settings_gridsize) then
            local i
            strips[tracks[track_select].strip][page].graphics[gfx2_select].x = math.floor((mouse.mx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize
            strips[tracks[track_select].strip][page].graphics[gfx2_select].y = math.floor((mouse.my - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
            update_gfx = true
          end
        elseif draggfx2 ~= nil then
          draggfx2 = nil
          if MOUSE_over(obj.sections[60]) then
            --delete
            ctl_select = nil
            DeleteSelectedCtls()
            update_gfx = true
          end
        end             
        
      elseif submode == 2 then
  
        if gfx.mouse_wheel ~= 0 then
          local v = gfx.mouse_wheel/120
          if MOUSE_over(obj.sections[46]) then
            slist_offset = F_limit(slist_offset - v, 0, #strip_files)
            update_gfx = true
            gfx.mouse_wheel = 0
          end
          if MOUSE_over(obj.sections[47]) then
            sflist_offset = F_limit(sflist_offset - v, 0, #strip_folders)
            update_gfx = true
            gfx.mouse_wheel = 0
          end
        end
        
        if MOUSE_click(obj.sections[15]) then
          SaveStrip()
          update_gfx = true
        end
        
        if mouse.mx > obj.sections[10].x then
          if mouse.context == nil and MOUSE_click(obj.sections[10]) then
            if strips and tracks[track_select] and strips[tracks[track_select].strip] then
              for i = 1, #strips[tracks[track_select].strip][page].controls do
              
                local xywh
                xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x + obj.sections[10].x, 
                        y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y + obj.sections[10].y, 
                        w = strips[tracks[track_select].strip][page].controls[i].w, 
                        h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}
                if MOUSE_click(xywh) then
                  
                  local stripid = strips[tracks[track_select].strip][page].controls[i].id
                  if stripid ~= nil then
                    SelectStripElements(stripid)
                    mouse.context = 'dragctl'
                    dragctl = 'dragctl'
                    dragoff = {x = mouse.mx - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w - surface_offset.x,
                               y = mouse.my - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh - surface_offset.y}
                    
                    update_gfx = true
                  end
                end
              end
              if not mouse.context then
                ctl_select = nil
                gfx3_select = nil
              end  
            end
          end  
        end
        
        if mouse.context and mouse.context == 'dragctl' then
          if math.floor(mouse.mx/settings_gridsize) ~= math.floor(mouse.last_x/settings_gridsize) or math.floor(mouse.my/settings_gridsize) ~= math.floor(mouse.last_y/settings_gridsize) then
            local i
            local mx = mouse.mx
            local my = mouse.my
            local scale = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x = math.floor((mx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y = math.floor((my - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                               - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x
                                                                                       + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w/2
                                                                                       - (strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w*scale)/2)
            strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y
                                                                                       + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh/2
                                                                                       - (strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh*scale)/2)
            if #ctl_select > 1 then
              for i = 2, #ctl_select do
                scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x = math.floor((mx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize 
                                                                                   - ctl_select[i].relx
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y = math.floor((mouse.my - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
                                                                                   - ctl_select[i].rely
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x
                                                                                           + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w/2
                                                                                           - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale)/2)
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
                                                                                           + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh/2
                                                                                           - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale)/2)
              end
            end
            if gfx3_select and #gfx3_select > 0 then
              for i = 1, #gfx3_select do
                strips[tracks[track_select].strip][page].graphics[gfx3_select[i].ctl].x = math.floor((mx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize 
                                                                                   - gfx3_select[i].relx
                strips[tracks[track_select].strip][page].graphics[gfx3_select[i].ctl].y = math.floor((my - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                                   - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
                                                                                   - gfx3_select[i].rely
              end            
            end

            update_gfx = true
          end
        elseif dragctl ~= nil then
          dragctl = nil
          if MOUSE_over(obj.sections[60]) then
            --delete
            DeleteSelectedCtls()
            update_gfx = true
          end
        end      
        
        if MOUSE_click(obj.sections[47]) then
          local i = math.floor(((mouse.my - obj.sections[47].y)) / butt_h)-1
          if i == -1 then
            sflist_offset = sflist_offset - SF_butt_cnt
            if sflist_offset < 0 then
              sflist_offset = 0
            end
            update_gfx = true
          elseif i >= SF_butt_cnt then
            if sflist_offset + SF_butt_cnt-1 < #strip_folders then
              sflist_offset = sflist_offset + SF_butt_cnt
            end
            update_gfx = true
          elseif strip_folders[i + sflist_offset] then
            stripfol_select = i + sflist_offset
            PopulateStrips()            
            update_gfx = true
          end
          
        end

        if MOUSE_click(obj.sections[46]) then
          local i = math.floor(((mouse.my - obj.sections[46].y)) / butt_h)-1
          if i == 0 then
            slist_offset = slist_offset - S_butt_cnt
            if slist_offset < 0 then
              slist_offset = 0
            end
            update_gfx = true
          elseif i >= S_butt_cnt then
            if slist_offset + S_butt_cnt-1 < #strip_files then
              slist_offset = slist_offset + S_butt_cnt-1
            end
            update_gfx = true
          elseif strip_files[i-1 + slist_offset] then
            strip_select = i-1 + slist_offset
            --gen preview
            loadstrip = LoadStrip(strip_select)
            if loadstrip then
              GenStripPreview(gui, loadstrip.strip)
                        
              mouse.context = 'dragstrip'
            end
            update_gfx = true
          end
          
        end
        
        if mouse.context and mouse.context == 'dragstrip' then
          if mouse.mx ~= mouse.last_x or mouse.my ~= mouse.last_y then
            dragstrip = {x = mouse.mx, y = mouse.my}
            update_gfx = true
          end
        elseif dragstrip ~= nil then
          --Dropped
          image_count = image_count_add
          if dragstrip.x > obj.sections[10].x and dragstrip.x < obj.sections[10].w and dragstrip.y > obj.sections[10].y and dragstrip.y < obj.sections[10].h then
            if surface_size.limit then
              Strip_AddStrip(loadstrip, dragstrip.x-obj.sections[10].x, dragstrip.y-obj.sections[10].y)
            else            
              Strip_AddStrip(loadstrip, dragstrip.x, dragstrip.y)
            end
          end
          
          --loadstrip = nil
          loadstrip = nil
          dragstrip = nil
          ctl_select = nil
          update_gfx = true
        end
        
      end
      
      if MOUSE_click(obj.sections[13]) then
        ctl_select = nil
        gfx3_select = nil
        submode = submode + 1
        if submode+1 > #submode_table then
          submode = 0
        end
        update_gfx = true

      elseif MOUSE_click_RB(obj.sections[13]) then
        ctl_select = nil
        gfx3_select = nil
        submode = submode - 1
        if submode < 0 then
          submode = #submode_table-1
        end
        update_gfx = true
        
      end
          
    end
    
    if mouse.context == nil then
      if ctl_select ~= nil and MOUSE_click(obj.sections[45]) then
      elseif mouse.mx > obj.sections[10].x then
      
        if MOUSE_click(obj.sections[10]) then
          mouse.context = "dragsurface"
          surx = surface_offset.x
          sury = surface_offset.y
          mmx = mouse.mx
          mmy = mouse.my
          ctl_select = nil
          gfx3_select = nil
        end

      end    
    end
    if mouse.context and mouse.context == "dragsurface" then
      local offx, offy
      if lockx == false then
        offx = MOUSE_surfaceX(obj.sections[10])
      end
      if locky == false then  
        offy = MOUSE_surfaceY(obj.sections[10])
      end
      
      if surface_size.w < obj.sections[10].w then
        surface_offset.x = -math.floor((obj.sections[10].w - surface_size.w)/2)
      elseif offx ~= nil then
        if locky == false then
          surface_offset.x = F_limit(surx + offx,0-math.ceil(obj.sections[10].w*0.25),surface_size.w - math.ceil(obj.sections[10].w*0.75))
        else
          surface_offset.x = F_limit(surx + offx,0,surface_size.w - obj.sections[10].w)        
        end
      end
      
      if offy ~= nil then
        if lockx == false then
          surface_offset.y = F_limit(sury + offy,0-math.ceil(obj.sections[10].h*0.25),surface_size.h - math.ceil(obj.sections[10].h*0.75))
        else
          surface_offset.y = F_limit(sury + offy,0,surface_size.h - obj.sections[10].h)        
        end
      end

      if surface_offset.oldx ~= surface_offset.x or surface_offset.oldy ~= surface_offset.y or (ctls and not ctl_select) then
        surface_offset.oldx = surface_offset.x
        surface_offset.oldy = surface_offset.y
        
        if strips and tracks[track_select] and strips[tracks[track_select].strip] then
          strips[tracks[track_select].strip][page].surface_x = surface_offset.x
          strips[tracks[track_select].strip][page].surface_y = surface_offset.y
        end
        if surface_offset.x < 0 or surface_offset.y < 0 
            or surface_offset.x > surface_size.w-obj.sections[10].w 
            or surface_offset.y > surface_size.h-obj.sections[10].h then 
          update_surfaceedge = true 
        end
        update_surface = true
      end
    end
    
    if gfx.mouse_wheel ~= 0 then
      if lockx == false or locky == false then
        local v = gfx.mouse_wheel/120
        if mouse.mx > obj.sections[10].x and MOUSE_over(obj.sections[10]) then
          if ctl_select then
            ctl_select = nil
            update_gfx = true
          end
          if locky then
            surface_offset.x = F_limit(surface_offset.x - v * 50,0,surface_size.w - obj.sections[10].w)
          elseif lockx then
            surface_offset.y = F_limit(surface_offset.y - v * 50,0,surface_size.h - obj.sections[10].h)        
          else
            surface_offset.y = F_limit(surface_offset.y - v * 50,0-math.ceil(obj.sections[10].h*0.25),surface_size.h - math.ceil(obj.sections[10].h*0.75))
          end
          if strips and tracks[track_select] and strips[tracks[track_select].strip] then
            strips[tracks[track_select].strip][page].surface_x = surface_offset.x
            strips[tracks[track_select].strip][page].surface_y = surface_offset.y
          end
          if surface_offset.x < 0 or surface_offset.y < 0 
              or surface_offset.x > surface_size.w-obj.sections[10].w 
              or surface_offset.y > surface_size.h-obj.sections[10].h then 
            update_surfaceedge = true 
          end
          update_surface = true
        end
      end
      gfx.mouse_wheel = 0
    end
        
    end

    if not mouse.LB and not mouse.RB then mouse.context = nil end
    
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    if char == 27 then quit() end     
    if char ~= -1 then reaper.defer(run) else quit() end
    gfx.update()
    mouse.last_LB = mouse.LB
    mouse.last_RB = mouse.RB
    mouse.last_x = mouse.mx
    mouse.last_y = mouse.my
    if ctl_select then ctls = true else ctls = false end
      
  end
  
  function SetCtlEnabled(fxnum)
  
    local i
    local enabled = reaper.TrackFX_GetEnabled(GetTrack(tracks[track_select].tracknum),fxnum)
    for i = 1, #strips[tracks[track_select].strip][page].controls do
      if strips[tracks[track_select].strip][page].controls[i].fxnum == fxnum then
        strips[tracks[track_select].strip][page].controls[i].dirty = true
      end
    end
    
  end
  
  function GetControlTable(c)
  
    local tbl = {fxname=strips[tracks[track_select].strip][page].controls[c].fxname,
                 fxguid=strips[tracks[track_select].strip][page].controls[c].fxguid, 
                 fxnum=strips[tracks[track_select].strip][page].controls[c].fxnum, 
                 fxfound = strips[tracks[track_select].strip][page].controls[c].fxfound,
                 param = strips[tracks[track_select].strip][page].controls[c].param,
                 param_info = strips[tracks[track_select].strip][page].controls[c].param_info,
                 ctltype = strips[tracks[track_select].strip][page].controls[c].ctltype,
                 knob_select = strips[tracks[track_select].strip][page].controls[c].knob_select,
                 ctl_info = {fn = strips[tracks[track_select].strip][page].controls[c].ctl_info.fn,
                             frames = strips[tracks[track_select].strip][page].controls[c].ctl_info.frames,
                             imageidx = strips[tracks[track_select].strip][page].controls[c].ctl_info.imageidx, 
                             cellh = strips[tracks[track_select].strip][page].controls[c].ctl_info.cellh},
                 x = strips[tracks[track_select].strip][page].controls[c].x,
                 y = strips[tracks[track_select].strip][page].controls[c].y,
                 w = strips[tracks[track_select].strip][page].controls[c].w,
                 scale = strips[tracks[track_select].strip][page].controls[c].scale,
                 xsc = strips[tracks[track_select].strip][page].controls[c].xsc,
                 ysc = strips[tracks[track_select].strip][page].controls[c].ysc,
                 wsc = strips[tracks[track_select].strip][page].controls[c].wsc,
                 hsc = strips[tracks[track_select].strip][page].controls[c].hsc,
                 show_paramname = strips[tracks[track_select].strip][page].controls[c].show_paramname,
                 show_paramval = strips[tracks[track_select].strip][page].controls[c].show_paramval,
                 ctlname_override = strips[tracks[track_select].strip][page].controls[c].ctlname_override,
                 textcol = strips[tracks[track_select].strip][page].controls[c].textcol,
                 textoff = strips[tracks[track_select].strip][page].controls[c].textoff,
                 textoffval = strips[tracks[track_select].strip][page].controls[c].textoffval,
                 textsize = strips[tracks[track_select].strip][page].controls[c].textsize,
                 val = strips[tracks[track_select].strip][page].controls[c].val,
                 defval = strips[tracks[track_select].strip][page].controls[c].defval,
                 maxdp = strips[tracks[track_select].strip][page].controls[c].maxdp,
                 id = strips[tracks[track_select].strip][page].controls[c].id
                 }
    return tbl
  end
  
  BGCOL=0xFFFFFF
  
  function setcolor(i)
    gfx.set(((i>>16)&0xFF)/0xFF, ((i>>8)&0xFF)/0xFF, (i&0xFF)/0xFF)
  end
  
  
  ---- editbox ----
  
  function editbox_draw(gui, e)
  
    f_Get_SSV('0 0 0')
    gfx.a = 1
    gfx.rect(obj.sections[8].x,obj.sections[8].y,obj.sections[8].w,obj.sections[8].h,true)
  
    GUI_DrawButton(gui, 'OK', obj.sections[6], gui.color.blue, gui.color.black, true)
    GUI_DrawButton(gui, 'Cancel', obj.sections[7], gui.color.blue, gui.color.black, true)
  
    GUI_textsm_LJ(gui, obj.sections[5], e.title, gui.color.white, 0)
  
    e.x = obj.sections[9].x
    e.y = obj.sections[9].y
    e.w = obj.sections[9].w
    e.h = obj.sections[9].h
    
    setcolor(e.bgcol)
    gfx.rect(e.x,e.y,e.w,e.h,true)
    setcolor(e.hasfocus and e.fgfcol or e.fgcol)
    gfx.rect(e.x,e.y,e.w,e.h,false)
    gfx.setfont(e.font) 
    setcolor(e.txtcol)
    local w,h=gfx.measurestr(e.text)
    local ox,oy=e.x+e.l,e.y+(e.h-h)/2
    gfx.x,gfx.y=ox,oy
    gfx.drawstr(e.text)
    if e.sel ~= 0 then
      local sc,ec=e.caret,e.caret+e.sel
      if sc > ec then sc,ec=ec,sc end
      local sx=gfx.measurestr(string.sub(e.text, 0, sc))
      local ex=gfx.measurestr(string.sub(e.text, 0, ec))
      setcolor(e.txtcol)
      gfx.rect(ox+sx, oy, ex-sx, h, true)
      setcolor(e.bgcol)
      gfx.x,gfx.y=ox+sx,oy
      gfx.drawstr(string.sub(e.text, sc+1, ec))
    end 
    if e.hasfocus then
      if e.cursstate < 8 then   
        w=gfx.measurestr(string.sub(e.text, 0, e.caret))    
        setcolor(e.curscol)
        gfx.line(e.x+e.l+w, e.y+2, e.x+e.l+w, e.y+e.h-4)
      end
      e.cursstate=(e.cursstate+1)%16
    end
  end
  
  function editbox_getcaret(e)
    local len=string.len(e.text)
    for i=1,len do
      w=gfx.measurestr(string.sub(e.text,1,i))
      if gfx.mouse_x < e.x+e.l+w then return i-1 end
    end
    return len
  end
  
  function editbox_onmousedown(e)
    e.hasfocus=
      gfx.mouse_x >= editbox.x and gfx.mouse_x < editbox.x+editbox.w and
      gfx.mouse_y >= editbox.y and gfx.mouse_y < editbox.y+editbox.h    
    if e.hasfocus then
      e.caret=editbox_getcaret(e) 
      e.cursstate=0
    end
    e.sel=0 
  end
  
  function editbox_onmousedoubleclick(e)
    local len=string.len(e.text)
    e.caret=len ; e.sel=-len
  end
  
  function editbox_onmousemove(e)
    e.sel=editbox_getcaret(e)-e.caret
  end
  
  function editbox_onchar(e, c)
    if e.sel ~= 0 then
      local sc,ec=e.caret,e.caret+e.sel
      if sc > ec then sc,ec=ec,sc end
      e.text=string.sub(e.text,1,sc)..string.sub(e.text,ec+1)
      e.sel=0
    end
    if c == 0x6C656674 then -- left arrow
      if e.caret > 0 then e.caret=e.caret-1 end
    elseif c == 0x72676874 then -- right arrow
      if e.caret < string.len(e.text) then e.caret=e.caret+1 end
    elseif c == 8 then -- backspace
      if e.caret > 0 then 
        e.text=string.sub(e.text,1,e.caret-1)..string.sub(e.text,e.caret+1)
        e.caret=e.caret-1
      end
    elseif c >= 32 and c <= 125 and string.len(e.text) < e.maxlen then
      e.text=string.format("%s%c%s", 
        string.sub(e.text,1,e.caret), c, string.sub(e.text,e.caret+1))
      e.caret=e.caret+1
    end
  end
  
  ---- generic mouse handling ----
  
  mouse={}
  
  function OnMouseDown()
    editbox_onmousedown(editbox)    
    mouse.down=true ; mouse.capcnt=0
    mouse.ox,mouse.oy=gfx.mouse_x,gfx.mouse_y
  end
  
  function OnMouseDoubleClick()
    if editbox.hasfocus then editbox_onmousedoubleclick(editbox) end
  end
  
  function OnMouseMove()
    if editbox.hasfocus then editbox_onmousemove(editbox) end  
    mouse.lx,mouse.ly=gfx.mouse_x,gfx.mouse_y
    mouse.capcnt=mouse.capcnt+1
  end
  
  function OnMouseUp()
    mouse.down=false
    mouse.uptime=os.clock()
  end
    
  --gfx.setfont(1,"verdana",editbox.fontsz)
  
  --reaper.defer(runloop)  
  
  function CheckTrackExists(s)
    local found = false
    local trx = GetTrack(strips[s].track.tracknum)
    if trx then
      if strips[s].track.guid ~= reaper.GetTrackGUID(trx) then
        --Find track and update tracknum
        for i = 0, reaper.CountTracks(0) do
          local tr = GetTrack(i)
          if tr ~= nil then
            if strips[s].track.guid == reaper.GetTrackGUID(tr) then
              --found
              found = true
              strips[s].track.tracknum = i
              break 
            end
          end
        end
      else
        found = true
      end
    else
      for i = 0, reaper.CountTracks(0) do
        local tr = GetTrack(i)
        if tr ~= nil then
          if strips[s].track.guid == reaper.GetTrackGUID(tr) then
            --found
            found = true
            strips[s].track.tracknum = i
            break 
          end
        end
      end
      --PopulateTracks()    
    end
    return found
  end

  
  function GPES(key, nilallowed)
    if nilallowed == nil then nilallowed = false end
    
    local _, val = reaper.GetProjExtState(0,SCRIPT,key)
    if nilallowed then
      if val == '' then
        val = nil
      end
    end
    return val
  end

  function GES(key, nilallowed)
    if nilallowed == nil then nilallowed = false end
    
    local val = reaper.GetExtState(SCRIPT,key)
    if nilallowed then
      if val == '' then
        val = nil
      end
    end
    return val
  end
    
  function LoadData()
  
    local s, p, c, g, k
  
    if GPES('savedok') ~= '' then
  
      local rv, v = reaper.GetProjExtState(0,SCRIPT,'version')
      if v ~= '' then
  
        PROJECTID = tonumber(GPES('projectid'))
        settings_gridsize = tonumber(nz(GPES('gridsize',true),settings_gridsize))
        settings_showgrid = tobool(nz(GPES('showgrid',true),true))
        show_editbar = tobool(nz(GPES('showeditbar',true),true))
        ogrid = settings_gridsize
        osg = settings_showgrid
      
        local scnt = tonumber(nz(GPES('strips_count'),0))
  
        strips = {}
        local ss = 1
        if scnt > 0 then
          for s = 1, scnt do
          
            key = 'strips_'..s..'_'
            
            strips[ss] = {}
            
            strips[ss].page = tonumber(nz(GPES(key..'page',true),1))

            key = 'strips_'..s..'_track_'

            strips[ss].track = {
                               name = GPES(key..'name'),
                               guid = GPES(key..'guid'),
                               tracknum = tonumber(GPES(key..'tracknum')),
                               strip = tonumber(GPES(key..'strip'))
                              }
            if CheckTrackExists(ss) then
              for p = 1, 4 do
              
                local key = 'strips_'..s..'_'..p..'_'
              
                strips[ss][p] = {
                                surface_x = tonumber(GPES(key..'surface_x')),
                                surface_y = tonumber(GPES(key..'surface_y')),
                                controls = {},
                                graphics = {}
                               }          
              
                local ccnt = tonumber(GPES(key..'controls_count'))
                local gcnt = tonumber(GPES(key..'graphics_count'))
              
                if ccnt > 0 then
                  for c = 1, ccnt do
    
                    local key = 'strips_'..s..'_'..p..'_controls_'..c..'_'
                            
                    strips[ss][p].controls[c] = {
                                                fxname = GPES(key..'fxname'),
                                                fxguid = GPES(key..'fxguid'),
                                                fxnum = tonumber(GPES(key..'fxnum')),
                                                fxfound = tobool(GPES(key..'fxfound')),
                                                param = tonumber(GPES(key..'param')),
                                                param_info = {
                                                              paramname = GPES(key..'param_info_name'),
                                                              paramnum = tonumber(GPES(key..'param_info_paramnum'))
                                                             },
                                                ctltype = tonumber(GPES(key..'ctltype')),
                                                knob_select = tonumber(GPES(key..'knob_select')),
                                                ctl_info = {
                                                            fn = GPES(key..'ctl_info_fn'),
                                                            frames = tonumber(GPES(key..'ctl_info_frames')),
                                                            imageidx = tonumber(GPES(key..'ctl_info_imageidx')),
                                                            cellh = tonumber(GPES(key..'ctl_info_cellh'))
                                                           },
                                                x = tonumber(GPES(key..'x')),
                                                y = tonumber(GPES(key..'y')),
                                                w = tonumber(GPES(key..'w')),
                                                scale = tonumber(GPES(key..'scale')),
                                                show_paramname = tobool(GPES(key..'show_paramname')),
                                                show_paramval = tobool(GPES(key..'show_paramval')),
                                                ctlname_override = nz(GPES(key..'ctlname_override'),''),
                                                textcol = GPES(key..'textcol'),
                                                textoff = tonumber(GPES(key..'textoff')),
                                                textoffval = tonumber(nz(GPES(key..'textoffval',true),0)),
                                                textsize = tonumber(nz(GPES(key..'textsize'),0)),
                                                val = tonumber(GPES(key..'val')),
                                                defval = tonumber(GPES(key..'defval')),
                                                maxdp = tonumber(nz(GPES(key..'maxdp',true),-1)),
                                                id = deconvnum(GPES(key..'id',true))
                                                --enabled = tobool(nz(GPES(key..'enabled',true),true))
                                               }
                    if strips[ss][p].controls[c].maxdp == nil or (strips[ss][p].controls[c].maxdp and strips[ss][p].controls[c].maxdp == '') then
                      strips[ss][p].controls[c].maxdp = -1
                    end
                    strips[ss][p].controls[c].xsc = strips[ss][p].controls[c].x + strips[ss][p].controls[c].w/2 - (strips[ss][p].controls[c].w*strips[ss][p].controls[c].scale)/2
                    strips[ss][p].controls[c].ysc = strips[ss][p].controls[c].y + strips[ss][p].controls[c].ctl_info.cellh/2 - (strips[ss][p].controls[c].ctl_info.cellh*strips[ss][p].controls[c].scale)/2
                    strips[ss][p].controls[c].wsc = strips[ss][p].controls[c].w*strips[ss][p].controls[c].scale
                    strips[ss][p].controls[c].hsc = strips[ss][p].controls[c].ctl_info.cellh*strips[ss][p].controls[c].scale
                    
    
                    --load control images - reshuffled to ensure no wasted slots between sessions
                    local iidx
                    local knob_sel = -1
                    for k = 1, #ctl_files do
                      if ctl_files[k].fn == strips[ss][p].controls[c].ctl_info.fn then
                        knob_sel = k
                        break
                      end
                    end
                    if knob_sel ~= -1 then
                      strips[ss][p].controls[c].knob_select = knob_sel
    
                      if ctl_files[knob_sel].imageidx == nil then
                        image_count = image_count + 1
                        gfx.loadimg(image_count, controls_path..ctl_files[knob_sel].fn)
                        iidx = image_count
                        
                        strips[ss][p].controls[c].ctl_info.imageidx = iidx
                        ctl_files[knob_sel].imageidx = iidx                    
                      else
                        iidx = ctl_files[knob_sel].imageidx
                        strips[ss][p].controls[c].ctl_info.imageidx = iidx
                      end
                    else
                      --missing
                      strips[ss][p].controls[c].knob_select = -1
                      strips[ss][p].controls[c].ctl_info.imageidx = 1020
                    end
                  end
                end
                
                if gcnt > 0 then
                
                  for g = 1, gcnt do
    
                    local key = 'strips_'..s..'_'..p..'_graphics_'..g..'_'
                    
                    strips[ss][p].graphics[g] = {
                                                fn = GPES(key..'fn'),
                                                imageidx = tonumber(GPES(key..'imageidx')),
                                                x = tonumber(GPES(key..'x')),
                                                y = tonumber(GPES(key..'y')),
                                                w = tonumber(GPES(key..'w')),
                                                h = tonumber(GPES(key..'h')),
                                                scale = tonumber(GPES(key..'scale')),
                                                id = deconvnum(GPES(key..'id',true))
                                               }
                    --load graphics images
                    local iidx
                    local gfx_sel = -1
                    for k = 0, #graphics_files do
                      if graphics_files[k].fn == strips[ss][p].graphics[g].fn then
                        gfx_sel = k
                        break
                      end
                    end
                    if gfx_sel ~= -1 then
                      
                      if graphics_files[gfx_sel].imageidx == nil then
                        image_count = image_count + 1
                        gfx.loadimg(image_count, graphics_path..graphics_files[gfx_sel].fn)
                        iidx = image_count
                        
                        strips[ss][p].graphics[g].imageidx = iidx
                        graphics_files[gfx_sel].imageidx = iidx                    
      
                      else
                        iidx = graphics_files[gfx_sel].imageidx
                        strips[ss][p].graphics[g].imageidx = iidx                                  
                      end
                    else
                      --missing
                      strips[ss][p].graphics[g].imageidx = 1020
                    end
                  end                
                end
              end
              ss = ss + 1
            else
              --not found
              --strips[s] = nil
            end
          end
        end
      else
        SaveData()
      end
      PopulateTracks() --must be called to link tracks to strips
      
      if show_editbar then
        plist_w = oplist_w
      else
        plist_w = 0
      end
      local ww, wh = GPES('win_w',true), GPES('win_h',true)
      if ww ~= nil and wh ~= nil then
        gfx1 = {main_w = tonumber(ww),
                main_h = tonumber(wh)}
      else    
        gfx1 = {main_w = 800,
                main_h = 450}
      end    
    else
      --error with saved data
      SaveData()
      PopulateTracks() --must be called to link tracks to strips
      
      local ww, wh = GPES('win_w',true), GPES('win_h',true)
      if ww ~= nil and wh ~= nil then
        gfx1 = {main_w = tonumber(ww),
                main_h = tonumber(wh)}
      else    
        gfx1 = {main_w = 800,
                main_h = 450}
      end    
        
    end
    --[[local ww = gfx1.main_w-(plist_w+2)
    if surface_size.w < ww then
      surface_offset.x = -math.floor((ww - surface_size.w)/2)
    end]]
    
  end
  
  function LoadSettings()
    settings_saveallfxinststrip = tobool(nz(GES('saveallfxinststrip',true),settings_saveallfxinststrip))
    settings_followselectedtrack = tobool(nz(GES('followselectedtrack',true),settings_followselectedtrack))
    settings_autocentrectls = tobool(nz(GES('autocentrectls',true),settings_autocentrectls))
    settings_updatefreq = tonumber(nz(GES('updatefreq',true),settings_updatefreq))
    dockstate = nz(GES('dockstate',true),0)
    lockx = tobool(nz(GES('lockx',true),false))
    locky = tobool(nz(GES('locky',true),false))
    lockw = tonumber(nz(GES('lockw',true),128))
    lockh = tonumber(nz(GES('lockh',true),128))
  end
  
  function SaveSettings()
    reaper.SetExtState(SCRIPT,'saveallfxinststrip',tostring(settings_saveallfxinststrip), true)
    reaper.SetExtState(SCRIPT,'followselectedtrack',tostring(settings_followselectedtrack), true)
    reaper.SetExtState(SCRIPT,'autocentrectls',tostring(settings_autocentrectls), true)
    reaper.SetExtState(SCRIPT,'updatefreq',settings_updatefreq, true)
    local d = gfx.dock(-1)
    reaper.SetExtState(SCRIPT,'dockstate',d, true)
    reaper.SetExtState(SCRIPT,'lockx',tostring(lockx), true)
    reaper.SetExtState(SCRIPT,'locky',tostring(locky), true)
    reaper.SetExtState(SCRIPT,'lockw',tostring(lockw), true)
    reaper.SetExtState(SCRIPT,'lockh',tostring(lockh), true)
  end
  
  function SaveData()
  
    SaveSettings()
    
    local s, p, c, g
    reaper.SetProjExtState(0,SCRIPT,"","") -- clear first
    
    reaper.SetProjExtState(0,SCRIPT,'version',VERSION)
    reaper.SetProjExtState(0,SCRIPT,'projectid',PROJECTID)
    reaper.SetProjExtState(0,SCRIPT,'gridsize',settings_gridsize)
    reaper.SetProjExtState(0,SCRIPT,'showgrid',tostring(settings_showgrid))
    reaper.SetProjExtState(0,SCRIPT,'showeditbar',tostring(show_editbar))
    
    if gfx1 then
      reaper.SetProjExtState(0,SCRIPT,'win_w',nz(gfx1.main_w,800))
      reaper.SetProjExtState(0,SCRIPT,'win_h',nz(gfx1.main_h,450))    
    end
        
    if strips and #strips > 0 then
    
      reaper.SetProjExtState(0,SCRIPT,'strips_count',#strips)    
      
      for s = 1, #strips do
        
        local key = 'strips_'..s..'_'

        reaper.SetProjExtState(0,SCRIPT,key..'page',nz(strips[s].page,1))

        key = 'strips_'..s..'_track_'
        
        reaper.SetProjExtState(0,SCRIPT,key..'name',strips[s].track.name)
        reaper.SetProjExtState(0,SCRIPT,key..'guid',strips[s].track.guid)
        reaper.SetProjExtState(0,SCRIPT,key..'tracknum',strips[s].track.tracknum)
        reaper.SetProjExtState(0,SCRIPT,key..'strip',strips[s].track.strip)
        
        for p = 1, 4 do

          local key = 'strips_'..s..'_'..p..'_'

          if strips[s][p] then
          
            reaper.SetProjExtState(0,SCRIPT,key..'surface_x',strips[s][p].surface_x)
            reaper.SetProjExtState(0,SCRIPT,key..'surface_y',strips[s][p].surface_y)
            reaper.SetProjExtState(0,SCRIPT,key..'controls_count',#strips[s][p].controls)
            reaper.SetProjExtState(0,SCRIPT,key..'graphics_count',#strips[s][p].graphics)
  
            if #strips[s][p].controls > 0 then
              for c = 1, #strips[s][p].controls do
  
                local key = 'strips_'..s..'_'..p..'_controls_'..c..'_'
  
                reaper.SetProjExtState(0,SCRIPT,key..'fxname',strips[s][p].controls[c].fxname)
                reaper.SetProjExtState(0,SCRIPT,key..'fxguid',nz(strips[s][p].controls[c].fxguid,''))
                reaper.SetProjExtState(0,SCRIPT,key..'fxnum',strips[s][p].controls[c].fxnum)
                reaper.SetProjExtState(0,SCRIPT,key..'fxfound',tostring(strips[s][p].controls[c].fxfound))
                reaper.SetProjExtState(0,SCRIPT,key..'param',strips[s][p].controls[c].param)
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_name',strips[s][p].controls[c].param_info.paramname)
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_paramnum',strips[s][p].controls[c].param_info.paramnum)
                reaper.SetProjExtState(0,SCRIPT,key..'ctltype',strips[s][p].controls[c].ctltype)
                reaper.SetProjExtState(0,SCRIPT,key..'knob_select',strips[s][p].controls[c].knob_select)
                reaper.SetProjExtState(0,SCRIPT,key..'ctl_info_fn',strips[s][p].controls[c].ctl_info.fn)
                reaper.SetProjExtState(0,SCRIPT,key..'ctl_info_frames',strips[s][p].controls[c].ctl_info.frames)
                reaper.SetProjExtState(0,SCRIPT,key..'ctl_info_imageidx',strips[s][p].controls[c].ctl_info.imageidx)
                reaper.SetProjExtState(0,SCRIPT,key..'ctl_info_cellh',strips[s][p].controls[c].ctl_info.cellh)
                reaper.SetProjExtState(0,SCRIPT,key..'x',strips[s][p].controls[c].x)
                reaper.SetProjExtState(0,SCRIPT,key..'y',strips[s][p].controls[c].y)
                reaper.SetProjExtState(0,SCRIPT,key..'w',strips[s][p].controls[c].w)
                reaper.SetProjExtState(0,SCRIPT,key..'scale',strips[s][p].controls[c].scale)
                reaper.SetProjExtState(0,SCRIPT,key..'show_paramname',tostring(strips[s][p].controls[c].show_paramname))
                reaper.SetProjExtState(0,SCRIPT,key..'show_paramval',tostring(strips[s][p].controls[c].show_paramval))
                reaper.SetProjExtState(0,SCRIPT,key..'ctlname_override',nz(strips[s][p].controls[c].ctlname_override,''))
                reaper.SetProjExtState(0,SCRIPT,key..'textcol',strips[s][p].controls[c].textcol)
                reaper.SetProjExtState(0,SCRIPT,key..'textoff',strips[s][p].controls[c].textoff)
                reaper.SetProjExtState(0,SCRIPT,key..'textoffval',strips[s][p].controls[c].textoffval)
                reaper.SetProjExtState(0,SCRIPT,key..'textsize',nz(strips[s][p].controls[c].textsize,0))
                reaper.SetProjExtState(0,SCRIPT,key..'val',strips[s][p].controls[c].val)
                reaper.SetProjExtState(0,SCRIPT,key..'defval',strips[s][p].controls[c].defval)   
                reaper.SetProjExtState(0,SCRIPT,key..'maxdp',nz(strips[s][p].controls[c].maxdp,-1))   
                           
                reaper.SetProjExtState(0,SCRIPT,key..'id',convnum(strips[s][p].controls[c].id))
          
              end
            end        

            if #strips[s][p].graphics > 0 then
              for g = 1, #strips[s][p].graphics do
            
                local key = 'strips_'..s..'_'..p..'_graphics_'..g..'_'
                
                reaper.SetProjExtState(0,SCRIPT,key..'fn',strips[s][p].graphics[g].fn)
                reaper.SetProjExtState(0,SCRIPT,key..'imageidx',strips[s][p].graphics[g].imageidx)
                reaper.SetProjExtState(0,SCRIPT,key..'x',strips[s][p].graphics[g].x)
                reaper.SetProjExtState(0,SCRIPT,key..'y',strips[s][p].graphics[g].y)
                reaper.SetProjExtState(0,SCRIPT,key..'w',strips[s][p].graphics[g].w)
                reaper.SetProjExtState(0,SCRIPT,key..'h',strips[s][p].graphics[g].h)
                reaper.SetProjExtState(0,SCRIPT,key..'scale',strips[s][p].graphics[g].scale)
                reaper.SetProjExtState(0,SCRIPT,key..'id',convnum(strips[s][p].graphics[g].id))
              
              end
            end

          else
            reaper.SetProjExtState(0,SCRIPT,key..'surface_x',0)
            reaper.SetProjExtState(0,SCRIPT,key..'surface_y',0)
            reaper.SetProjExtState(0,SCRIPT,key..'controls_count',0)
            reaper.SetProjExtState(0,SCRIPT,key..'graphics_count',0)          
          end
                            
        end    
      end
    else
      reaper.SetProjExtState(0,SCRIPT,'strips_count',0)    
    end
  
    reaper.SetProjExtState(0,SCRIPT,'savedok',tostring(true))
  
  end
  
  function convnum(val)
  
    if val == nil then
      val = -0xFFFFFF
    end
    return val
       
  end
  
  function deconvnum(val)
    
    if tonumber(val) == -0xFFFFFF then
      val = nil
    else
      val = tonumber(val)
    end
    return val
       
  end
    
  ------------------------------------------------------------
  
  function SetSurfaceSize()
  
    gfx.setimgdim(1000,surface_size.w, surface_size.h)
    gfx.setimgdim(1004,surface_size.w, surface_size.h)
      
  end
  
  ------------------------------------------------------------
    
  function INIT()

    PROJECTID = math.ceil((math.abs(math.sin( -1 + (os.clock() % 2)))) * 0xFFFFFFFF)
    
    mode = 0
    submode = 2
    butt_h = 20
    fx_h = 160
  
    ogrid = settings_gridsize
    sb_size = 3
    
    P_butt_cnt = 0
    F_butt_cnt = 0
    G_butt_cnt = 0
    S_butt_cnt = 0
    SF_butt_cnt = 0
    tlist_offset = 0
    sflist_offset = 0
    
    strips = {}
    surface_offset = {x = 0, y = 0}
    
    image_count = 1
    knob_select = 0
    ksel_size = 50
    ksel_loaded = false
    page = 1
    
    gfx_select = 0
    track_select = 0
    trackfx_select = 0
    trackfxparam_select = 0
    ctl_select = nil
    scale_select = 1
    textcol_select = '205 205 205'
    ctltype_select = 1
    textoff_select = 45
    textoffval_select = 0
    textsize_select = 0
    defval_select = 0
    strip_select = 0
    stripfol_select = 0
    maxdp_select = -1
    
    plist_w = 140
    oplist_w = 140
    
    time_nextupdate = 0
    
    show_ctloptions = false
    show_editbar = true
    show_settings = false
    
    show_paramname = true
    show_paramval = true
    
    last_gfx_w = 0
    last_gfx_h = 0
    
    octlval = -1
    otrkcnt = -1
    ofxcnt = -1
    
    lockx = false
    locky = false
    lockw, olockw = 0, 0
    lockh, olockh = 0, 0
  
    PopulateGFX()
    PopulateControls()
    PopulateStripFolders()
    PopulateStrips()
    
    EB_Open = 0
    MS_Open = 0
    
    update_gfx = true
    update_surface = true
    update_ctls = true
    update_sidebar = true
    update_topbar = true
    update_ctlopts = true
    force_gfx_update = true
    
    mouse = {}
    
    SetSurfaceSize()
    
  end
  
  ------------------------------------------------------------

  SCRIPT = 'LBX_STRIPPER'
  VERSION = 0.91

  resource_path = reaper.GetResourcePath().."/Scripts/LBX/LBXCS_resources/"
  controls_path = resource_path.."controls/"
  graphics_path = resource_path.."graphics/"
  icon_path = resource_path.."icons/"
  strips_path = resource_path.."strips/"

  settings_followselectedtrack = true
  settings_autocentrectls = true
  settings_gridsize = 16
  settings_showgrid = true
  osg = settings_showgrid
  settings_saveallfxinststrip = false
  settings_updatefreq = 0.05
  settings_showbars = true
  
  dockstate = 0
  
  surface_size = {w = 2048, h = 2048, limit = true}
  
  gfx.loadimg(0,controls_path.."__default.png") -- default control
  gfx.loadimg(1021,icon_path.."bin.png")
  gfx.loadimg(1020,controls_path.."ledstrip4.png")
  
  INIT()
  LoadSettings()
  LoadData()  
  Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h) 

  gfx.dock(dockstate)
  run()
  
  reaper.atexit()
  
  ------------------------------------------------------------
  
  function quit()
  
    SaveData()
    SaveSettings()
    gfx.quit()
    
  end
