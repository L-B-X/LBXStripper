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
  ctltype_table = {'KNOB/SLIDER','BUTTON','BUTTON INV','CYCLE BUTTON','METER','MEM BUTTON'}
  trctltype_table = {'Track Controls','Track Sends'}
  scalemode_preset_table = {'','NORMAL','REAPER VOL'}
  scalemode_table = {1/8,1/7,1/6,1/5,1/4,1/3,1/2,1,2,3,4,5,6,7,8}
  scalemode_dtable = {'1/8','1/7','1/6','1/5','1/4','1/3','1/2','1','2','3','4','5','6','7','8'}
  
  framemode_table = {'NORMAL','CIRC'}
  
  trctltypeidx_table = {tr_ctls = 1,
                        tr_sends = 2,
                        tr_rcvs = 3,
                        tr_hwouts = 4
                       }  
      
  contexts = {updatefreq = 0,
              lockw = 1,
              lockh = 2,
              gridslider = 3,
              dragsidebar = 4,
              sliderctl = 5,
              scaleslider = 6,
              offsetslider = 7,
              valoffsetslider = 8,
              defvalslider = 9,
              textsizeslider = 10,
              dragctl = 11,
              draglasso = 12,
              dragparam = 13,
              draggfx = 14,
              stretch_x = 15,
              stretch_y = 16,
              stretch_xy = 17,
              draggfx2 = 18,
              dragstrip = 19,
              cycleknob = 20,
              dragparamlrn = 21,
              minov = 22,
              maxov = 23,
              dragparam_tr = 24,
              dragparam_snd = 25,
              shadxslider = 26,
              shadyslider = 27,
              shadaslider = 28,
              movesnapwindow = 29,
              resizesnapwindow = 30
              }
  
  ctlcats = {fxparam = 0,
             trackparam = 1,
             tracksend = 2,
             trackrecv = 3,
             trackhwout = 4}
             
  gfxtype = {img = 0,
             txt = 1
             }
                        
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
  if gentables then
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
  else
    --error
  end
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
    if g then
      return string.match(g,'{(.*)}')
    end
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
      obj.sections[10] = {x = plist_w+2 + sb_size + 2,
                          y = butt_h+2 + sb_size + 2,
                          w = gfx1.main_w-(plist_w+2+(sb_size+2)*2),
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
                          h = fx_h}
      --PARAMS
      obj.sections[42] = {x = 0,
                          y = obj.sections[41].y + obj.sections[41].h + 10,
                          w = plist_w,
                          h = gfx1.main_h - (obj.sections[41].y + obj.sections[41].h + 10)}
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
      local cow = 140
      obj.sections[45] = {x = gfx1.main_w - cow - 20,
                          y = gfx1.main_h - 440 -20,
                          w = cow,
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

      --LEARN+TRX
      obj.sections[48] = {x = 0,
                          y = obj.sections[41].y+obj.sections[41].h+8,
                          w = plist_w,
                          h = butt_h}                           

      --LABEL OPTS
      obj.sections[49] = {x = gfx1.main_w - cow - 20,
                          y = gfx1.main_h - 300 -20,
                          w = cow,
                          h = 300}                           
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
      obj.sections[67] = {x = obj.sections[45].x+10,
                          y = obj.sections[45].y+150+butt_h+10 + (butt_h/2+4 + 10) * 8,
                          w = 35,
                          h = butt_h/2+8}

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
      local setw, seth = 300, 230                            
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
      obj.sections[81] = {x = obj.sections[70].x+xofft,
                                y = obj.sections[70].y+yoff + yoffm*7,
                                w = bw,
                                h = bh}
                                
      --Cycle
      local cw, ch = 140, 360
      obj.sections[100] = {x = obj.sections[45].x - cw - 10,
                           y = obj.sections[45].y + obj.sections[45].h - ch,
                           w = cw,
                           h = ch}

      local kw,_ = gfx.getimgdim(0)
      local kh = defctls[def_knob].cellh
      obj.sections[101] = {x = obj.sections[100].x+obj.sections[100].w/2-kw/2,
                           y = obj.sections[100].y+butt_h/2,
                           w = kw,
                           h = kh}
      obj.sections[102] = {x = obj.sections[100].x+obj.sections[100].w-40-10,
                           y = obj.sections[101].y+obj.sections[101].h+butt_h,
                           w = 40,
                           h = bh}

      obj.sections[103] = {x = obj.sections[100].x+8,
                           y = obj.sections[102].y+bh+40+butt_h,
                           w = obj.sections[100].w-16,
                           h = butt_h*8}

      obj.sections[104] = {x = obj.sections[102].x,
                           y = obj.sections[102].y-bh-2,
                           w = 40,
                           h = obj.sections[102].h}
      
      obj.sections[105] = {x = obj.sections[103].x,
                           y = obj.sections[103].y-butt_h,
                           w = obj.sections[103].w,
                           h = butt_h}
      obj.sections[106] = {x = obj.sections[103].x-2,
                           y = obj.sections[103].y+obj.sections[103].h+2,
                           w = obj.sections[103].w+4,
                           h = butt_h}
      obj.sections[107] = {x = obj.sections[102].x,
                           y = obj.sections[102].y+obj.sections[102].h+4,
                           w = bh,
                           h = bh}
      
      obj.sections[115] = {x = obj.sections[43].x+obj.sections[43].w+20,
                           y = obj.sections[43].y+20,
                           w = 140,
                           h = 200}
      obj.sections[116] = {x = obj.sections[115].x,
                           y = obj.sections[115].y+butt_h*4,
                           w = obj.sections[115].w,
                           h = obj.sections[115].h-(obj.sections[115].y+butt_h*4)}
      --learn track
      obj.sections[117] = {x = obj.sections[115].x,
                           y = obj.sections[115].y+butt_h,
                           w = obj.sections[115].w,
                           h = butt_h}
      --learn fx
      obj.sections[118] = {x = obj.sections[115].x,
                           y = obj.sections[115].y+butt_h*2,
                           w = obj.sections[115].w,
                           h = butt_h}
      --learn param
      obj.sections[119] = {x = obj.sections[115].x,
                           y = obj.sections[115].y+butt_h*3,
                           w = obj.sections[115].w,
                           h = butt_h}
      
      --CTL OPTIONS PG 2
      obj.sections[125] = {x = obj.sections[45].x+60,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 0,
                          w = obj.sections[45].w-70,
                          h = butt_h/2+8}

      obj.sections[126] = {x = obj.sections[45].x+60,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 5,
                          w = obj.sections[45].w-70,
                          h = butt_h/2+8}
      obj.sections[127] = {x = obj.sections[45].x+60,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 6,
                          w = obj.sections[45].w-70,
                          h = butt_h/2+8}
      local kwh = defctls[def_knobsm].cellh
      obj.sections[128] = {x = obj.sections[45].x+15,
                           y = obj.sections[45].y+butt_h+20 + (butt_h/2+4 + 10) * 1,
                          w = kwh,
                          h = kwh}
      obj.sections[129] = {x = obj.sections[45].x+10 + kwh+20,
                           y = obj.sections[45].y+butt_h+20 + (butt_h/2+4 + 10) * 1,
                          w = kwh,
                          h = kwh}
      obj.sections[130] = {x = obj.sections[45].x+20,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 4,
                          w = obj.sections[45].w-40,
                          h = butt_h/2+4}

      obj.sections[131] = {x = obj.sections[45].x+70,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 8,
                          w = obj.sections[45].w-80,
                          h = butt_h/2+8}
      obj.sections[132] = {x = obj.sections[45].x+70,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 9,
                          w = obj.sections[45].w-80,
                          h = butt_h/2+8}
      obj.sections[133] = {x = obj.sections[45].x+70,
                          y = obj.sections[45].y+butt_h+10 + (butt_h/2+4 + 10) * 10,
                          w = obj.sections[45].w-80,
                          h = butt_h/2+8}

      --LBL OPTIONS 
      --EDIT
      obj.sections[140] = {x = obj.sections[49].x+20,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 0,
                          w = obj.sections[49].w-40,
                          h = butt_h/2+8}                       

      local yo = 5
      obj.sections[141] = {x = obj.sections[49].x+50,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 2 + yo,
                          w = obj.sections[49].w-60,
                          h = butt_h/2+4}                           

      obj.sections[142] = {x = obj.sections[49].x+obj.sections[49].w-40-butt_h/2+4,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 3 + yo,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           
      obj.sections[143] = {x = obj.sections[49].x+obj.sections[49].w-40-butt_h/2+4,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 4 + yo,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           
      obj.sections[144] = {x = obj.sections[49].x+obj.sections[49].w-40-butt_h/2+4,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 5 + yo,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           
      obj.sections[145] = {x = obj.sections[49].x+obj.sections[49].w-40-butt_h/2+4,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 6 + yo,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           
      obj.sections[146] = {x = obj.sections[49].x+obj.sections[49].w-40-butt_h/2+4,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 7 + yo,
                          w = butt_h/2+4,
                          h = butt_h/2+4}                           

      obj.sections[147] = {x = obj.sections[49].x+20,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 1,
                          w = obj.sections[49].w-40,
                          h = butt_h/2+8}                       

      obj.sections[148] = {x = obj.sections[49].x+50,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 8 + yo,
                          w = obj.sections[49].w-60,
                          h = butt_h/2+4}                           
      obj.sections[149] = {x = obj.sections[49].x+50,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 9 + yo,
                          w = obj.sections[49].w-60,
                          h = butt_h/2+4}                           
      obj.sections[150] = {x = obj.sections[49].x+50,
                          y = obj.sections[49].y+butt_h+10 + (butt_h/2+4 + 10) * 10 + yo,
                          w = obj.sections[49].w-60,
                          h = butt_h/2+4}
                          
      --SNAPSHOTS
      local ssh = snaph-116
      obj.sections[160] = {x = gfx1.main_w - 160 - (sb_size+2),
                          y = gfx1.main_h - snaph - (sb_size+2),
                          w = 160,
                          h = snaph}                            
      obj.sections[161] = {x = 20,
                          y = butt_h+10 + (butt_h/2+4 + 10) * 0,
                          w = obj.sections[160].w-40,
                          h = butt_h/2+8}                       
      obj.sections[162] = {x = 20,
                          y = butt_h+10 + (butt_h/2+4 + 10) * 1,
                          w = obj.sections[160].w-40,
                          h = butt_h/2+8}                       
      obj.sections[163] = {x = 10,
                          y = butt_h+10 + (butt_h/2+4 + 10) * 3,
                          w = obj.sections[160].w-20,
                          h = ssh}                       
      --dummy for locating
      --obj.sections[164] = {x = obj.sections[160].x+10,
      --                    y = obj.sections[160].y+butt_h+10 + (butt_h/2+4 + 10) * 3,
      --                    w = obj.sections[160].w-20,
      --                    h = ssh}                       

      obj.sections[165] = {x = 0,
                          y = obj.sections[160].h-6,
                          w = obj.sections[160].w,
                          h = 6}                       
      
    return obj
  end
  
  -----------------------------------------------------------------------     
  
  function GetGUI_vars()
    gfx.mode = 0
    
    local gui = {}
      gui.aa = 1
      gui.fontname = fontname_def
      gui.fontsize_tab = 20    
      gui.fontsz_knob = fontsize_def

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
        text = nz(text,'')
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

  function GUI_textsm_CJ(gui, xywh, text, c, offs, limitx)
        text = nz(text,'')
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
        gfx.x, gfx.y = xywh.x+(xywh.w-text_len)/2,xywh.y+(xywh.h-gfx.texth)/2 + 1
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
        text = nz(text,'')
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

  function Strip_AddGFX(type)

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
      
      if type == gfxtype.img then
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
        strips[strip][page].graphics[gfxnum] = {gfxtype = type,
                                          fn = graphics_files[gfx_select].fn,
                                          imageidx = graphics_files[gfx_select].imageidx,
                                          x = x,
                                          y = y,
                                          w = w,
                                          h = h,
                                          scale = 1,
                                          stretchw = w,
                                          stretchh = h,
                                          font = {idx = nil,
                                                  name = nil,
                                                  size = nil,
                                                  bold = nil,
                                                  italics = nil,
                                                  underline = nil,
                                                  shadow = nil
                                                  },
                                          text = nil,
                                          text_col = nil,
                                          poslock = false
                                         }
      elseif type == gfxtype.txt then
        local x,y
        x = math.floor((label_add.x)/settings_gridsize)*settings_gridsize + math.floor(surface_offset.x/settings_gridsize)*settings_gridsize - math.floor((obj.sections[10].x)/settings_gridsize)*settings_gridsize
        y = math.floor((label_add.y)/settings_gridsize)*settings_gridsize + math.floor(surface_offset.y/settings_gridsize)*settings_gridsize - math.floor((obj.sections[10].y)/settings_gridsize)*settings_gridsize
        local w, h = 50, 50--gfx.getimgdim(graphics_files[gfx_select].imageidx)      
        gfxnum = #strips[strip][page].graphics + 1
        strips[strip][page].graphics[gfxnum] = {gfxtype = type,
                                          fn = '',
                                          imageidx = -1,
                                          x = x,
                                          y = y,
                                          w = w,
                                          h = h,
                                          scale = 1,
                                          stretchw = w,
                                          stretchh = h,
                                          font = {idx = gfx_font_select.idx,
                                                  name = gfx_font_select.name,
                                                  size = gfx_font_select.size,
                                                  bold = gfx_font_select.bold,
                                                  italics = gfx_font_select.italics,
                                                  underline = gfx_font_select.underline,
                                                  shadow = gfx_font_select.shadow,
                                                  shadow_x = gfx_font_select.shadow_x,
                                                  shadow_y = gfx_font_select.shadow_y,
                                                  shadow_a = gfx_font_select.shadow_a
                                                  },
                                          text = gfx_text_select,
                                          text_col = gfx_textcol_select,
                                          poslock = false
                                         }
      
      end
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
      if dragparam.type == 'track' then
        strips[strip][page].controls[ctlnum] = {c_id = GenID(),
                                                ctlcat = ctlcats.fxparam,
                                                fxname=trackfx[trackfx_select].name,
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
                                                val = GetParamValue(ctlcats.fxparam,
                                                                    tracks[trackedit_select].tracknum,
                                                                    trackfx[trackfx_select].fxnum,
                                                                    trackfxparam_select, nil),
                                                defval = GetParamValue(ctlcats.fxparam,
                                                                    tracks[trackedit_select].tracknum,
                                                                    trackfx[trackfx_select].fxnum,
                                                                    trackfxparam_select, nil),
                                                maxdp = maxdp_select,
                                                cycledata = {statecnt = 0, mapptof = false,{}},
                                                membtn = {state = false,
                                                          mem = nil},
                                                id = nil,
                                                tracknum = tracks[trackedit_select].tracknum,
                                                trackguid = tracks[trackedit_select].guid,
                                                scalemode = 8,
                                                framemode = 1
                                                }
        if track_select == trackedit_select then
          strips[strip][page].controls[ctlnum].tracknum = nil
          strips[strip][page].controls[ctlnum].trackguid = nil         
        end
      elseif dragparam.type == 'learn' then
        strips[strip][page].controls[ctlnum] = {c_id = GenID(),
                                                ctlcat = ctlcats.fxparam,
                                                fxname=last_touch_fx.fxname,
                                                fxguid=last_touch_fx.fxguid, 
                                                fxnum=last_touch_fx.fxnum, 
                                                fxfound = true,
                                                param = last_touch_fx.paramnum,
                                                param_info = {paramname = last_touch_fx.prname,
                                                              paramnum = last_touch_fx.paramnum},
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
                                                val = GetParamValue(ctlcats.fxparam,
                                                                    last_touch_fx.tracknum,
                                                                    last_touch_fx.fxnum,
                                                                    last_touch_fx.paramnum, nil),
                                                defval = GetParamValue(ctlcats.fxparam,
                                                                    last_touch_fx.tracknum,
                                                                    last_touch_fx.fxnum,
                                                                    last_touch_fx.paramnum, nil),
                                                maxdp = maxdp_select,
                                                cycledata = {statecnt = 0, mapptof = false,{}},
                                                membtn = {state = false,
                                                          mem = nil},
                                                id = nil,
                                                tracknum = last_touch_fx.tracknum,
                                                trackguid = last_touch_fx.trguid,
                                                scalemode = 8,
                                                framemode = 1
                                                }
        if last_touch_fx.tracknum == strips[strip].track.tracknum then
          strips[strip][page].controls[ctlnum].tracknum = nil
          strips[strip][page].controls[ctlnum].trackguid = nil 
        end      
      
      elseif dragparam.type == 'trctl' then
        strips[strip][page].controls[ctlnum] = {c_id = GenID(),
                                                ctlcat = ctlcats.trackparam,
                                                fxname='Track Parameter',
                                                fxguid=nil, 
                                                fxnum=nil, 
                                                fxfound = true,
                                                param = trctl_select,
                                                param_info = {paramname = 'Track '..trctls_table[trctl_select].name,
                                                              paramnum = trctl_select},
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
                                                val = GetParamValue(ctlcats.trackparam,
                                                                    tracks[trackedit_select].tracknum,
                                                                    nil,
                                                                    trctl_select, nil),
                                                defval = GetParamValue(ctlcats.trackparam,
                                                                    tracks[trackedit_select].tracknum,
                                                                    nil,
                                                                    trctl_select, nil),
                                                maxdp = maxdp_select,
                                                cycledata = {statecnt = 0, mapptof = false,{}},
                                                membtn = {state = false,
                                                          mem = nil},
                                                id = nil,
                                                tracknum = tracks[trackedit_select].tracknum,
                                                trackguid = tracks[trackedit_select].guid,
                                                scalemode = 8,
                                                framemode = 1
                                                }
        if track_select == trackedit_select then
          strips[strip][page].controls[ctlnum].tracknum = nil
          strips[strip][page].controls[ctlnum].trackguid = nil         
        end

      elseif dragparam.type == 'trsnd' then
        --local unique, guid = CheckTrackUnique(trsends_table[trctl_select].sendname)
        
        --if unique == true then 
          local sidx = math.floor((trctl_select-1) / 3)
          local pidx = (trctl_select-1) % 3 +1
          strips[strip][page].controls[ctlnum] = {c_id = GenID(),
                                                  ctlcat = ctlcats.tracksend,
                                                  fxname='Track Send',
                                                  fxguid=nil, 
                                                  fxnum=nil, 
                                                  fxfound = true,
                                                  param = trctl_select,
                                                  param_info = {paramname = trsends_table[sidx][pidx].name,
                                                                paramnum = trctl_select,
                                                                paramidx = trsends_table[sidx].idx,
                                                                paramstr = trsends_table[sidx][pidx].parmname,
                                                                paramdesttrnum = trsends_table[sidx].desttracknum,
                                                                paramdestguid = trsends_table[sidx].desttrackguid,
                                                                paramdestchan = trsends_table[sidx].dstchan,
                                                                paramsrcchan = trsends_table[sidx].srcchan},
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
                                                  val = 0,
                                                  defval = 0,
                                                  maxdp = maxdp_select,
                                                  cycledata = {statecnt = 0, mapptof = false,{}},
                                                  membtn = {state = false,
                                                            mem = nil},
                                                  id = nil,
                                                  tracknum = tracks[trackedit_select].tracknum,
                                                  trackguid = tracks[trackedit_select].guid,
                                                  scalemode = 8,
                                                  framemode = 1
                                                  }
          
          if track_select == trackedit_select then
            strips[strip][page].controls[ctlnum].tracknum = nil
            strips[strip][page].controls[ctlnum].trackguid = nil         
          end
          strips[strip][page].controls[ctlnum].val = GetParamValue(ctlcats.tracksend,
                                                                    tracks[trackedit_select].tracknum,
                                                                    nil,
                                                                    trctl_select, ctlnum)
          strips[strip][page].controls[ctlnum].defval = strips[strip][page].controls[ctlnum].val
          
        --else
          --not unique
        --  OpenMsgBox(1, 'Please ensure the target track name for send is unique.', 1)
        --end
      end                                              
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
          --def_knob = c
        end
        c = c + 1
      end
      i=i+1
      kf = reaper.EnumerateFiles(controls_path,i)
    end
    
  end

  function LoadControl(iidx, fn)

    if string.sub(fn,string.len(fn)-3) == '.knb' then
      local file
      file=io.open(controls_path..fn,"r")
      local content=file:read("*a")
      file:close()
      
      defctls[iidx] = unpickle(content)
      gfx.loadimg(iidx,controls_path..defctls[iidx].fn)
      return iidx
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

  function CheckTrackUnique(name)
  
    local cnt = 0
    local guid
    for i = 0, reaper.CountTracks(0)-1 do
    
      local track = GetTrack(i)
      if name == reaper.GetTrackState(track) then
        if guid == nil then
          guid = reaper.GetTrackGUID(track)
        end
        cnt = cnt + 1
      end          
    
    end
    local retval = true
    if cnt > 1 then
      guid = nil
      retval = false
    end
    return retval, guid
  
  end

  -------------------------------------------------------
  
  function split(str,sep)
      local array = {}
      local reg = string.format("([^%s]+)",sep)
      for mem in string.gmatch(str,reg) do
          --table.insert(array, mem)
          array[#array+1] = mem
      end
      return array
  end
  
  function trackfromguid(guid)
  
    local ret=-1
    local tr
    for t = 0, reaper.CountTracks(0)-1 do
    
      tr = reaper.GetTrack(0, t)
      if guid == reaper.GetTrackGUID(tr) then
        ret = t
        break
      end
    end
  
    return ret, tr
  end
  
  function CheckStripSends(tsends)
  
    if tsends == nil then
      tsends = {}
    end
    if track_select and tracks[track_select] and strips[tracks[track_select].strip] then
    
      local tn = strips[tracks[track_select].strip].track.tracknum
      if tsends[tn] == nil then
        tsends[tn] = PopSendInfo(tn)
      end
      
      if tsends and tsends[tn] then
        for c = 1, #strips[tracks[track_select].strip][page].controls do
          if strips[tracks[track_select].strip][page].controls[c].ctlcat == ctlcats.tracksend then
                  
            local paramnum = strips[tracks[track_select].strip][page].controls[c].param_info.paramnum
            local tnl = strips[tracks[track_select].strip][page].controls[c].tracknum
            if tnl == nil then
              tnl = tn
            elseif tsends[tnl] == nil then
              tsends[tnl] = PopSendInfo(tnl)
            end
            local sidx = math.floor((paramnum-1) / 3)
            local pidx = (paramnum-1) % 3 +1
            if tsends[tnl] and tsends[tnl][sidx] and strips[tracks[track_select].strip][page].controls[c].param_info.paramdestguid ==
               tsends[tnl][sidx].desttrackguid and
                   tsends[tnl][sidx].dstchan == strips[tracks[track_select].strip][page].controls[c].param_info.paramdestchan and
                   tsends[tnl][sidx].srcchan == strips[tracks[track_select].strip][page].controls[c].param_info.paramsrcchan then
            else   
              for i = 0, #tsends[tnl] do
                
                if tsends[tnl][i] and tsends[tnl][i].desttrackguid == strips[tracks[track_select].strip][page].controls[c].param_info.paramdestguid and
                   tsends[tnl][i].dstchan == strips[tracks[track_select].strip][page].controls[c].param_info.paramdestchan and
                   tsends[tnl][i].srcchan == strips[tracks[track_select].strip][page].controls[c].param_info.paramsrcchan then
                  strips[tracks[track_select].strip][page].controls[c].param_info.paramnum = i*3+pidx-1
                  strips[tracks[track_select].strip][page].controls[c].param_info.param = i*3+pidx-1
                  strips[tracks[track_select].strip][page].controls[c].param_info.paramidx = tsends[tnl][i].idx
                  break
                end 
              end
            end
          end
      
        end
      else
      end    
    end
  
    return tsends
  end
  
  function CheckSendGUID(tr, dtracknum, paramnum, guid, dstchan, srcchan, sendinfo)
 
    local check = false
    local sidx = math.floor((paramnum-1) / 3)
    local pidx = (paramnum-1) % 3 +1
    if sendinfo == nil then
      sendinfo = PopSendInfo(tr)
    end
    if sendinfo[sidx] and sendinfo[sidx].desttrackguid == guid and sendinfo[sidx].dstchan == dstchan and sendinfo[sidx].srcchan == srcchan then
      check = true
    end
    return check, sendinfo
    
  end
  
  function PopSendInfo(tr)
  
    if settings_ExtendedAPI == false then
      return PopSendInfoFromChunk(tr)
    else
    
      tbl = {}

      local track = GetTrack(tr)

      local sndcnt = reaper.GetTrackNumSends(track,0)
      for i = 0, sndcnt-1 do
        local dsttrack = reaper.BR_GetMediaTrackSendInfo_Track(track, 0, i, 1)
        if dsttrack then
          local guid = reaper.GetTrackGUID(dsttrack)
          local dst = reaper.GetTrackSendInfo_Value(track, 0, i, 'I_DSTCHAN')
          local src = reaper.GetTrackSendInfo_Value(track, 0, i, 'I_SRCCHAN')
  
          tbl[i] = {}
          local sname, _ = reaper.GetTrackState(dsttrack)
          
          t = -1 --not used
          tbl[i] = {idx = i,
                        sendname = sname,
                        desttracknum = t,
                        desttrackguid = guid,
                        dstchan = dst,
                        srcchan = src,
                        {}}
          tbl[i][1] = {
                                name = tostring(sname)..' Send Vol',
                                parmname = 'D_VOL'
                               }
          tbl[i][2] = {
                                name = tostring(sname)..' Send Pan',
                                parmname = 'D_PAN'
                               }
          tbl[i][3] = {
                                name = tostring(sname)..' Send Mute',
                                parmname = 'B_MUTE'
                               }
        end
      end    
    
      return tbl
    end
      
  end
    
  function PopSendInfoFromChunk(tr)
  
      tbl = {}
      local sidx = 0
      local auxrcv = ''
      for t = 0, reaper.CountTracks(0)-1 do    
      
        local track = GetTrack(t)
        local _, chunk = reaper.GetTrackStateChunk(track,'')
        local guid = reaper.GetTrackGUID(track)
        local s, e, le = _, 1, 0
        s,e = string.find(string.sub(chunk,e),'AUXRECV .-\n')
        while s and s > 0 do
          ns = le-1+s
          le = le + e
          
          auxrcv = string.sub(chunk,ns,le-1)
          local tx = split(auxrcv, ' ')
          src_tr = tonumber(tx[2])
          src = tonumber(tx[9])
          dst = tonumber(tx[10])
          
          if tonumber(src_tr) == tr then        
            tbl[sidx] = {}
            local sname, _ = reaper.GetTrackState(track)
            tbl[sidx] = {idx = sidx,
                          sendname = sname,
                          desttracknum = t,
                          desttrackguid = guid,
                          dstchan = dst,
                          srcchan = src,
                          {}}
            tbl[sidx][1] = {
                                  name = tostring(sname)..' Send Vol',
                                  parmname = 'D_VOL'
                                 }
            tbl[sidx][2] = {
                                  name = tostring(sname)..' Send Pan',
                                  parmname = 'D_PAN'
                                 }
            tbl[sidx][3] = {
                                  name = tostring(sname)..' Send Mute',
                                  parmname = 'B_MUTE'
                                 }
            
            sidx = sidx + 1
          end
          
          s,e = string.find(string.sub(chunk,le),'AUXRECV .-\n')
        end
      end
      return tbl
        
  end
  
  -------------------------------------------------------

  function PopulateTrackSendsInfo()
  
    --CheckStripSends()
    if tracks[trackedit_select] then
      trsends_table = PopSendInfo(tracks[trackedit_select].tracknum)
    end
    
    trsends_mmtable = {}
    
    trsends_mmtable[1] = {paramstr = 'D_VOL', min = 0, max = 4}
    trsends_mmtable[2] = {paramstr = 'D_PAN', min = -1, max = 1}
    trsends_mmtable[3] = {paramstr = 'B_MUTE', min = 0, max = 1}
    
  end

  -------------------------------------------------------

  function PopulateMediaItemInfo()
  
    trctls_table = {}
    trctls_table[1] = {idx = 1,
                       name = 'Volume',
                       parmname = 'D_VOL',
                       min = 0,
                       max = 4,
                       }
    trctls_table[2] = {idx = 2,
                       name = 'Pan',
                       parmname = 'D_PAN',
                       min = -1,
                       max = 1,
                       }
    trctls_table[3] = {idx = 3,
                       name = 'Width',
                       parmname = 'D_WIDTH',
                       min = -1,
                       max = 1,
                       }
    trctls_table[4] = {idx = 4,
                       name = 'Dual Pan L',
                       parmname = 'D_DUALPANL',
                       min = -1,
                       max = 1,
                       }
    trctls_table[5] = {idx = 5,
                       name = 'Dual Pan R',
                       parmname = 'D_DUALPANR',
                       min = -1,
                       max = 1,
                       }
    trctls_table[6] = {idx = 6,
                       name = 'Mute',
                       parmname = 'B_MUTE',
                       min = 0,
                       max = 1,
                       }
    trctls_table[7] = {idx = 7,
                       name = 'Solo',
                       parmname = 'I_SOLO',
                       min = 0,
                       max = 2,
                       }
    trctls_table[8] = {idx = 8,
                       name = 'Pan Mode',
                       parmname = 'I_PANMODE',
                       min = 0,
                       max = 6,
                       }
    trctls_table[9] = {idx = 9,
                       name = 'Record Arm',
                       parmname = 'I_RECARM',
                       min = 0,
                       max = 1,
                       }
    trctls_table[10] = {idx = 10,
                       name = 'FX Enabled',
                       parmname = 'I_FXEN',
                       min = 0,
                       max = 1,
                       }
    trctls_table[11] = {idx = 11,
                       name = 'Phase',
                       parmname = 'B_PHASE',
                       min = 0,
                       max = 1,
                       }
    
    
    
  end

  -------------------------------------------------------

  function PopulateTracks()
    local tracks_tmp = {}
    local sendsdirty = false
    for i = -1, reaper.CountTracks(0) do
      local track = GetTrack(i)
      if track ~= nil then
        local trname, _ = reaper.GetTrackState(track)
  
        tracks_tmp[i] = {name = trname,
                         guid = reaper.GetTrackGUID(track),
                         tracknum = i,
                         strip = -1
                        }
        
        --if tracks then
          --if tracks_tmp[i].guid ~= tracks[i].guid then
          --  sendsdirty = true
          --end
        --end
        if #strips > 0 then
          for j = 1, #strips do
            
            if strips[j].track.guid == tracks_tmp[i].guid then
              tracks_tmp[i].strip = j
              break
            end 
          end
        end
      end  
    end
    tracks = tracks_tmp
    --if sendsdirty == true then
      --CheckStripSends()
    --end
  end
  
  function PopulateTrackFX()
  
    trackfx = {}
    trackfx_select = 0
    flist_offset = 0

    if trackedit_select and tracks[trackedit_select] then
      local track = GetTrack(tracks[trackedit_select].tracknum)
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
    
    if trackedit_select then
      local track = GetTrack(tracks[trackedit_select].tracknum)
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
    gfx.rect(xywh.x+xywh.w/2,
     xywh.y, 
     2,
     xywh.h, 1 )
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[43].x,
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
    gfx.a = 1]]
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)

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
    
    F_butt_cnt = math.floor(obj.sections[41].h / butt_h) - 1
    
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

    if fxmode == 0 then
      for i = 0, F_butt_cnt-1 do
      
        if trackfx[i + flist_offset] then
          local xywh = {x = obj.sections[41].x,
                        y = obj.sections[41].y +2+ (i+1) * butt_h,
                        w = obj.sections[41].w,
                        h = butt_h}
          local c
          local bypassed = not GetFXEnabled(tracks[trackedit_select].tracknum, i+ flist_offset)
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
    elseif fxmode == 1 then
    
      for i = 0, F_butt_cnt-1 do
        
        if trctltype_table[i + trctltypelist_offset + 1] then
          local xywh = {x = obj.sections[41].x,
                        y = obj.sections[41].y +2+ (i+1) * butt_h,
                        w = obj.sections[41].w,
                        h = butt_h}
          local c = gui.color.white
          if trctltype_select == i + trctltypelist_offset then
            f_Get_SSV(gui.color.white)
            gfx.rect(xywh.x,
                     xywh.y, 
                     xywh.w,
                     xywh.h, 1, 1)
  
            c = gui.color.black
          end
          GUI_textsm_LJ(gui, xywh, trctltype_table[i + trctltypelist_offset + 1], c, -4, plist_w)
        else
          break
        end

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
    gfx.rect(xywh.x+xywh.w/2,
     xywh.y, 
     2,
     xywh.h, 1)
    
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[41].x,
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
    f_Get_SSV(gui.color.black)]]
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)

    --Params
    P_butt_cnt = math.floor(obj.sections[42].h / butt_h) - 3

    if fxmode == 0 then
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
    elseif fxmode == 1 then
      local tbl = {}
      if trctltype_select == 0 then
        --track controls
        tbl = trctls_table
      elseif trctltype_select == 1 then
        --track sends
        tbl = trsends_table
      elseif trctltype_select == 2 then
        --track receives
        
      elseif trctltype_select == 3 then
        --track h/w outs
      
      end
      
      if trctltype_select == 0 then
        for i = 0, #tbl-1 do
          if tbl[i + trctlslist_offset+1] then
            local xywh = {x = obj.sections[42].x,
                          y = obj.sections[42].y +2 + (i+1) * butt_h,
                          w = obj.sections[42].w,
                          h = butt_h}  
            local c = gui.color.white
            if trctl_select-1 == i + trctlslist_offset then  
              f_Get_SSV(gui.color.white)
              gfx.rect(xywh.x,
                       xywh.y, 
                       xywh.w,
                       xywh.h, 1, 1)
              c = gui.color.black        
            end
            GUI_textsm_LJ(gui, xywh, tbl[i + trctlslist_offset+1].name, c, -4, plist_w)
          else
            break
          end
        end
      else
        for i = 0, (#tbl)*3+2 do
          local ii = i + trctlslist_offset
          local sidx = math.floor(ii / 3)
          local pidx = ii % 3 + 1
          if tbl[sidx] and tbl[sidx][pidx] then
            local xywh = {x = obj.sections[42].x,
                          y = obj.sections[42].y +2 + (i+1) * butt_h,
                          w = obj.sections[42].w,
                          h = butt_h}  
            local c = gui.color.white
            if trctl_select-1 == i + trctlslist_offset then  
              f_Get_SSV(gui.color.white)
              gfx.rect(xywh.x,
                       xywh.y, 
                       xywh.w,
                       xywh.h, 1, 1)
              c = gui.color.black        
            end
            GUI_textsm_LJ(gui, xywh, tbl[sidx][pidx].name, c, -4, plist_w)
          else
            break
          end
        end      
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
    gfx.rect(xywh.x+xywh.w/2,
     xywh.y, 
     2,
     xywh.h, 1 )
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[42].x,
                  y = obj.sections[43].h-butt_h-2,
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
    gfx.a = 1]]
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)

    f_Get_SSV(gui.color.white)
    gfx.a = 1  
    gfx.rect(obj.sections[48].x,
             obj.sections[48].y-butt_h, 
             obj.sections[48].w,
             obj.sections[48].h, 1)
             
    f_Get_SSV(gui.color.black)
    local xywh = {x = obj.sections[48].x+obj.sections[48].w - 40,
                  y = obj.sections[48].y-butt_h, 
                  w = 40,
                  h = obj.sections[48].h}
    
    gfx.rect(xywh.x,
             xywh.y, 
             2,
             xywh.h, 1)
    if fxmode == 0 then
      GUI_textC(gui,xywh,'LRN',gui.color.black,-2)
    end
    
    local xywh = {x = obj.sections[48].x,
                  y = obj.sections[48].y-butt_h, 
                  w = obj.sections[48].w-40,
                  h = obj.sections[48].h}
    if trackedit_select ~= track_select then
      f_Get_SSV(gui.color.red)
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               xywh.h, 1, 1)        
    end
    f_Get_SSV(gui.color.black)
    if trackedit_select >= 0 then
      GUI_textsm_CJ(gui,xywh,'TR'..trackedit_select+1 ..':'..tracks[trackedit_select].name,gui.color.black,-2,xywh.w)
    else
      GUI_textsm_CJ(gui,xywh,'TR: Master',gui.color.black,-2,xywh.w)        
    end                 

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
    gfx.rect(xywh.x+xywh.w/2,
             xywh.y, 
             2,
             xywh.h, 1 )
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[44].x,
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
    gfx.a = 1]]
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)
  
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
    gfx.rect(xywh.x+xywh.w/2,
             xywh.y, 
             2,
             xywh.h, 1 )
    gfx.a = 1
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[47].x,
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
    gfx.a = 1]]
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)

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
    gfx.rect(xywh.x+xywh.w/2,
             xywh.y, 
             2,
             xywh.h, 1 )
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)
     
    --[[local xywh = {x = obj.sections[46].x,
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
    gfx.a = 1]]
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)

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
        
          local gtype = strips[tracks[track_select].strip][page].graphics[i].gfxtype
          local x = strips[tracks[track_select].strip][page].graphics[i].x
          local y = strips[tracks[track_select].strip][page].graphics[i].y
          if not surface_size.limit then
            x = x + surface_offset.x 
            y = y + surface_offset.y 
          end
          
          if gtype == gfxtype.img then
            local w = strips[tracks[track_select].strip][page].graphics[i].w
            local h = strips[tracks[track_select].strip][page].graphics[i].h
            local sw = strips[tracks[track_select].strip][page].graphics[i].stretchw
            local sh = strips[tracks[track_select].strip][page].graphics[i].stretchh
            local imageidx = strips[tracks[track_select].strip][page].graphics[i].imageidx
            
            local yoff = 0
            local xoff = 0
            if not surface_size.limit then
              if x+sw > obj.sections[10].x + obj.sections[10].w then
                sw = obj.sections[10].x + obj.sections[10].w - x
              end
              if x < obj.sections[10].x then
                xoff = obj.sections[10].x - x
              end
              if y+sh > obj.sections[10].y + obj.sections[10].h then
                sh = obj.sections[10].y + obj.sections[10].h - y
              end
              if y < obj.sections[10].y then
                yoff = obj.sections[10].y - y
              end
            end
            gfx.blit(imageidx,1,0, xoff, yoff, w, h-yoff, x+xoff, y+yoff, sw, sh)
          
          elseif gtype == gfxtype.txt then
            --local w = strips[tracks[track_select].strip][page].graphics[i].w
            --local h = strips[tracks[track_select].strip][page].graphics[i].h
            local text = strips[tracks[track_select].strip][page].graphics[i].text
            local textcol = strips[tracks[track_select].strip][page].graphics[i].text_col
            
            local flagb,flagi,flagu = 0,0,0
            if strips[tracks[track_select].strip][page].graphics[i].font.bold then
              flagb = 98
            end
            if strips[tracks[track_select].strip][page].graphics[i].font.italics then
              flagi = 105
            end
            if strips[tracks[track_select].strip][page].graphics[i].font.underline then
              flagu = 117
            end
            local flags = flagb + (flagi*256) + (flagu*(256^2))
            gfx.setfont(1,strips[tracks[track_select].strip][page].graphics[i].font.name,
                          strips[tracks[track_select].strip][page].graphics[i].font.size,flags)
            local w, h = gfx.measurestr(text)
            strips[tracks[track_select].strip][page].graphics[i].w = w
            strips[tracks[track_select].strip][page].graphics[i].h = h            
            strips[tracks[track_select].strip][page].graphics[i].stretchw = w
            strips[tracks[track_select].strip][page].graphics[i].stretchh = h            
            if strips[tracks[track_select].strip][page].graphics[i].font.shadow then
            
              local shada = nz(strips[tracks[track_select].strip][page].graphics[i].font.shadow_a,0.6)
              local shadx = nz(strips[tracks[track_select].strip][page].graphics[i].font.shadow_x,1)
              local shady = nz(strips[tracks[track_select].strip][page].graphics[i].font.shadow_y,1)
              --local shadoff = F_limit(math.ceil((strips[tracks[track_select].strip][page].graphics[i].font.size/250)*10),1,15)
            
              f_Get_SSV(gui.color.black)
              gfx.a = shada
              gfx.x, gfx.y = x+shadx,y+shady
              gfx.drawstr(text)
            end
            
            gfx.a = 1
            gfx.x, gfx.y = x,y
            f_Get_SSV(textcol)
            
            gfx.drawstr(text)
          
          end
          
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

  function GUI_DrawCycleOptions(obj, gui)
  
    gfx.dest = 1

    f_Get_SSV('0 0 0')
    gfx.a = 1  
    gfx.rect(obj.sections[100].x,
             obj.sections[100].y, 
             obj.sections[100].w,
             obj.sections[100].h, 1 )
    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(obj.sections[100].x,
             obj.sections[100].y, 
             obj.sections[100].w,
             obj.sections[100].h, 0 )
    
    f_Get_SSV('0 0 0')
    
    f_Get_SSV(gui.color.white)
    local xywh = {x = obj.sections[100].x,
                  y = obj.sections[100].y-butt_h,
                  w = obj.sections[100].w,
                  h = butt_h}
            
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )
    GUI_textC(gui,xywh,'CYCLE OPTS',gui.color.black,-2)
  
    --local p = F_limit(math.floor(Cycle_Norm(cycle_select.val,ctl_select[1].ctl)*(defctls[def_knob].frames-1)),0,defctls[def_knob].frames-1)
    local p = F_limit(math.floor(cycle_select.val*(defctls[def_knob].frames-1)),0,defctls[def_knob].frames-1)
    local kw, _ = gfx.getimgdim(0)
    local kh = defctls[def_knob].cellh
    gfx.blit(def_knob,1,0,0,p*kh,kw,kh,obj.sections[101].x,obj.sections[101].y)
    
    GUI_DrawButton(gui, cycle_select.statecnt, obj.sections[102], gui.color.white, gui.color.black, true, 'STATES')
    GUI_DrawButton(gui, 'AUTO', obj.sections[104], gui.color.white, gui.color.black, true)
    GUI_DrawTick(gui, 'POS TO FRAME', obj.sections[107], gui.color.white, nz(cycle_select.mapptof, false))
    GUI_DrawButton(gui, 'SAVE', obj.sections[106], gui.color.white, gui.color.black, true)

    local c

    f_Get_SSV('16 16 16')
    gfx.rect(obj.sections[103].x-2,
             obj.sections[103].y-2, 
             obj.sections[103].w+4,
             obj.sections[103].h+4, 1 )

    f_Get_SSV('64 64 64')
    gfx.rect(obj.sections[105].x-2,
             obj.sections[105].y, 
             obj.sections[105].w+4,
             obj.sections[105].h, 1 )

    f_Get_SSV('0 0 0')
    local xywh = {x = obj.sections[105].x,
                  y = obj.sections[105].y,
                  w = obj.sections[105].w/2,
                  h = butt_h}
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+4,xywh.x+xywh.w/2-6,xywh.y+xywh.h-4,xywh.x+xywh.w/2+6,xywh.y+xywh.h-4,1)
    xywh.x = obj.sections[105].x+obj.sections[105].w/2
    gfx.triangle(xywh.x+xywh.w/2,xywh.y+xywh.h-4,xywh.x+xywh.w/2-6,xywh.y+4,xywh.x+xywh.w/2+6,xywh.y+4,1)

    f_Get_SSV('0 0 0')
    gfx.rect(obj.sections[105].x+obj.sections[105].w/2,
             obj.sections[105].y, 
             2,
             obj.sections[105].h, 1 )
    
    if cycle_select.statecnt > 0 then
      
      f_Get_SSV('0 0 0')
      gfx.rect(obj.sections[103].x,
               obj.sections[103].y, 
               obj.sections[103].w,
               butt_h*F_limit(cycle_select.statecnt,0,8), 1 )
      if cycle_select.selected and cycle_select.selected-cyclist_offset <= 8 and cycle_select.selected-cyclist_offset > 0 then
        f_Get_SSV(gui.color.white)
        gfx.rect(obj.sections[103].x,
                 obj.sections[103].y+(cycle_select.selected-cyclist_offset-1)*butt_h, 
                 obj.sections[103].w,
                 butt_h, 1)
      end
      for i = 1, 8 do
      
        xywh = {x = obj.sections[103].x,
                y = obj.sections[103].y+(i-1)*butt_h,
                w = obj.sections[103].w,
                h = butt_h}
        if cycle_select[i+cyclist_offset] and i+cyclist_offset <= cycle_select.statecnt then
          c = gui.color.white
          if cycle_select.selected and cycle_select.selected == i+cyclist_offset then
            c = gui.color.black
          end
          
          GUI_textsm_LJ(gui,xywh,math.floor(i+cyclist_offset),c,-5)
          xywh.x = xywh.x + 20
          GUI_textsm_LJ(gui,xywh,cycle_select[i+cyclist_offset].dispval,c,-5,xywh.w-20)
        end
                
      end
    end  
  end

  ------------------------------------------------------------

  function GUI_DrawLblOptions(obj, gui)

    gfx.dest = 1

    local xywh = {x = obj.sections[49].x,
                  y = obj.sections[49].y,
                  w = obj.sections[49].w,
                  h = obj.sections[49].h}
    
    f_Get_SSV('0 0 0')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 0 )
    
    xywh.h = butt_h     
    f_Get_SSV(gui.color.white)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    GUI_textC(gui,xywh,'LABEL OPTS',gui.color.black,-2)

    GUI_DrawButton(gui, 'EDIT LABEL', obj.sections[140], gui.color.white, gui.color.black, true)
    GUI_DrawButton(gui, gfx_font_select.name, obj.sections[147], gui.color.white, gui.color.black, true)
    GUI_DrawSliderH(gui, 'F SIZE', obj.sections[141], gui.color.black, gui.color.white, F_limit(gfx_font_select.size/250,0,1))
    GUI_DrawColorBox(gui, 'LBL COL', obj.sections[142], gui.color.white, gfx_textcol_select)
    GUI_DrawTick(gui, 'BOLD', obj.sections[143], gui.color.white, gfx_font_select.bold)
    GUI_DrawTick(gui, 'ITALIC', obj.sections[144], gui.color.white, gfx_font_select.italics)
    GUI_DrawTick(gui, 'U/LINE', obj.sections[145], gui.color.white, gfx_font_select.underline)
    GUI_DrawTick(gui, 'SHADOW', obj.sections[146], gui.color.white, gfx_font_select.shadow)
    GUI_DrawSliderH(gui, 'SHAD X', obj.sections[148], gui.color.black, gui.color.white, F_limit((gfx_font_select.shadow_x+15)/30,0,1))
    GUI_DrawSliderH(gui, 'SHAD Y', obj.sections[149], gui.color.black, gui.color.white, F_limit((gfx_font_select.shadow_y+15)/30,0,1))
    GUI_DrawSliderH(gui, 'SHAD A', obj.sections[150], gui.color.black, gui.color.white, F_limit(gfx_font_select.shadow_a,0,1))

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

    f_Get_SSV('64 64 64')
    gfx.a = 1  
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 0 )
    
    xywh.h = butt_h     
    f_Get_SSV(gui.color.white)
    gfx.a = 1 
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )

    GUI_textC(gui,xywh,'CTL OPTIONS',gui.color.black,-2)
    xywh.x = xywh.x+xywh.w-20
    xywh.w = 20
    GUI_textC(gui,xywh,ctl_page+1,gui.color.black,-2)
    
    if ctl_page == 0 then
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
        gfx.blit(iidx,scale_select,0, 0, ctl_files[knob_select].cellh*math.floor((ctl_files[knob_select].frames-1)*0.75), w, ctl_files[knob_select].cellh, xywh.x + (xywh.w/2-(w*scale_select)/2), xywh.y + (62.5 - (ctl_files[knob_select].cellh*scale_select)/2))
        xywh = {x = obj.sections[45].x,
                y = obj.sections[45].y+butt_h,
                w = obj.sections[45].w,
                h = butt_h}
        gfx.a = 0.75
        
        f_Get_SSV('0 0 0')
        gfx.rect(xywh.x+1,
                 xywh.y,
                 xywh.w-2,
                 xywh.h,1)        
        GUI_textC(gui,xywh,ctl_files[knob_select].fn,gui.color.white,-5)
  
      end
          
      GUI_DrawSliderH(gui, 'SCALE', obj.sections[50], gui.color.black, gui.color.white, (scale_select-0.5)*2)
      GUI_DrawTick(gui, 'SHOW NAME', obj.sections[52], gui.color.white, show_paramname)
      GUI_DrawTick(gui, 'SHOW VALUE', obj.sections[53], gui.color.white, show_paramval)
      GUI_DrawColorBox(gui, 'TEXT COL', obj.sections[54], gui.color.white, textcol_select)
      GUI_DrawButton(gui, ctltype_table[ctltype_select], obj.sections[55], gui.color.white, gui.color.black, true)
      GUI_DrawSliderH(gui, 'OFFSET', obj.sections[56], gui.color.black, gui.color.white, F_limit((textoff_select+150)/300,0,1))
      GUI_DrawSliderH(gui, 'VAL OFF', obj.sections[65], gui.color.black, gui.color.white, F_limit((textoffval_select+50)/100,0,1))
      GUI_DrawSliderH(gui, 'F SIZE', obj.sections[58], gui.color.black, gui.color.white, (textsize_select+2)/35)
      GUI_DrawSliderH(gui, 'DEF VAL', obj.sections[57], gui.color.black, gui.color.white, F_limit(defval_select,0,1))
      GUI_DrawButton(gui, 'SET', obj.sections[51], gui.color.white, gui.color.black, true)
      GUI_DrawButton(gui, 'EDIT NAME', obj.sections[59], gui.color.white, gui.color.black, true)
      
      if ctltype_select == 4 then
        if show_cycleoptions then
          GUI_DrawButton(gui, '>>', obj.sections[67], gui.color.white, gui.color.black, true)
        else
          GUI_DrawButton(gui, '<<', obj.sections[67], gui.color.white, gui.color.black, true)
        end  
      end
      
      local mdptxt = maxdp_select
      if maxdp_select < 0 then
        mdptxt = 'OFF'
      end
      GUI_DrawButton(gui, mdptxt, obj.sections[66], gui.color.white, gui.color.black, true, 'MAX DP')

    elseif ctl_page == 1 then

      GUI_DrawButton(gui, dvaloff_select, obj.sections[125], gui.color.white, gui.color.black, true, 'VDISP OFF')

      local min, max = GetParamMinMax_ctlselect()
      if minov_select == nil then
        minov_select = min
      end
      if maxov_select == nil then
        maxov_select = max
      end
      GUI_DrawButton(gui, minov_select, obj.sections[126], gui.color.white, gui.color.black, true, 'MIN OV', true)
      GUI_DrawButton(gui, maxov_select, obj.sections[127], gui.color.white, gui.color.black, true, 'MAX OV', true)
      GUI_DrawButton(gui, nz(ov_disp,''), obj.sections[130], gui.color.black, gui.color.white, true, '')
      GUI_DrawButton(gui, scalemode_preset_table[knob_scalemode_select], obj.sections[131], gui.color.white, gui.color.black, true, 'SCALE PSET')
      GUI_DrawButton(gui, scalemode_dtable[scalemode_select], obj.sections[132], gui.color.white, gui.color.black, true, 'SCALE MOD')
      GUI_DrawButton(gui, framemode_table[framemode_select], obj.sections[133], gui.color.white, gui.color.black, true, 'FRAME MOD')

      local pmin = normalize(min, max, minov_select)
      local pmax = normalize(min, max, maxov_select)
      local w, _ = gfx.getimgdim(def_knobsm)
      gfx.blit(def_knobsm,1,0, 0, defctls[def_knobsm].cellh*math.floor((defctls[def_knobsm].frames-1)*pmin), w, defctls[def_knobsm].cellh, obj.sections[128].x, obj.sections[128].y)
      gfx.blit(def_knobsm,1,0, 0, defctls[def_knobsm].cellh*math.floor((defctls[def_knobsm].frames-1)*pmax), w, defctls[def_knobsm].cellh, obj.sections[129].x, obj.sections[129].y)
    
    end
        
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

  function GUI_DrawButton(gui, t, b, colb, colt, v, opttxt, limit)

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
    if limit~=nil and limit==true then
      GUI_textsm_LJ(gui,xywh,t,colt,-4,b.w)
    else
      GUI_textC(gui,xywh,t,colt,-4)
    end
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
      if n and tonumber(n) then
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

  function GetNumericPart(num)
    local s, e = string.find(num,'%-%d+.%d+')
    if s == nil then
      s, e = string.find(num,'%d+.%d+')
    end
    if s and e then  
      local n = string.sub(num,s,e)
      if n and tonumber(n) then
        res = tonumber(n)
        return res
      else
        return num
      end
    else
      local s, e = string.find(num,'%-%d+')
      if s == nil then
        s, e = string.find(num,'%d+')
      end
      if s and e then  
        local n = string.sub(num,s,e)
        if n and tonumber(n) then
          res = tonumber(n)
          return res
        else
          return num
        end
      else
        return num
      end
    end
  end

  function dvaloffset(num, dvoff)
    if dvoff and dvoff ~= 0 then
      local s, e = string.find(num,'%-%d+.%d+')
      if s == nil then
        s, e = string.find(num,'%d+.%d+')
      end
      if s and e then  
        local n = string.sub(num,s,e)
        if n and tonumber(n) then
          res = tonumber(n) + dvoff
          return string.sub(num,1,s-1) .. res .. string.sub(num,e+1)
        else
          return num
        end
      else
        local s, e = string.find(num,'%-%d+')
        if s == nil then
          s, e = string.find(num,'%d+')
        end
        if s and e then  
          local n = string.sub(num,s,e)
          if n and tonumber(n) then
            res = tonumber(n) + dvoff
            return string.sub(num,1,s-1) .. res .. string.sub(num,e+1)
          else
            return num
          end
        else
          return num
        end
      end
    else
      return num
    end
  end
  
  function nz(val, d)
    if val == nil then return d else return val end
  end
  
  ------------------------------------------------------------

local function inQuart(t, b, c, d)
  t = t / d
  return c * t^4 + b
end

function outCubic(t, b, c, d)
  t = t / d - 1
  return c * ((t^3) + 1) + b
end

function outQuart(t, b, c, d)
  t = t / d - 1
  return -c * (t^4 - 1) + b
end

function outQuint(t, b, c, d)
  t = t / d - 1
  return c * ((t^5) + 1) + b
end

function inExpo(t, b, c, d)
  if t == 0 then
    return b
  else
    return c * 2^(10 * (t / d - 1)) + b - c * 0.001
  end
end

function outExpo(t, b, c, d)
  if t == d then
    return b + c
  else
    return c * 1.001 * -2^((-10 * t / d) + 1) + b
  end
end

function outCirc(t, b, c, d)
  t = t - 1
  return(math.sqrt(1 - t^2)) 
end

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

        local trackM = GetTrack(strips[tracks[track_select].strip].track.tracknum)
        if trackM == nil then 
          if CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip) then
            trackM = GetTrack(strips[tracks[track_select].strip].track.tracknum)
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
              local val = math.floor(100*nz(strips[tracks[track_select].strip][page].controls[i].val,0))
              local ctlcat = strips[tracks[track_select].strip][page].controls[i].ctlcat
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
              local dvoff = strips[tracks[track_select].strip][page].controls[i].dvaloffset
              local tnum = strips[tracks[track_select].strip][page].controls[i].tracknum

              if fxnum == nil then return end
    
              local track = trackM
              if tnum ~= nil then
                track = GetTrack(tnum)
                if track == nil then return end
              else
                tnum = strips[tracks[track_select].strip].track.tracknum
              end
    
              if mode == 1 and submode == 1 then
                gfx.a = 0.5
              else
                gfx.a = 1
              end

              gfx.setfont(1, gui.fontname, gui.fontsz_knob +tsz-4)
              local _, th_a = gfx.measurestr('|')
              local to = th_a

              local Disp_ParamV
              local Disp_Name
              local v2, val2

              --if ctlcat == ctlcats.fxparam then
                v2 = frameScale(strips[tracks[track_select].strip][page].controls[i].framemode, GetParamValue2(ctlcat,track,fxnum,param,i))
                --v2 = outCirc(v2)
                val2 = F_limit(round(frames*v2),0,frames-1)
                
                local DVOV
                if ctltype == 3 then
                  --invert button
                  val2 = 1-val2
                elseif ctltype == 4 then
                  --cycle button
                  if strips[tracks[track_select].strip][page].controls[i].cycledata.mapptof then
                    --override val2
                    --prelim code for single state notify
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt == 1 then
                      local v3 = strips[tracks[track_select].strip][page].controls[i].val
                      --must convert to string to compare for some weird reason                
                      if tostring(v3) ~= tostring(strips[tracks[track_select].strip][page].controls[i].cycledata[1].val) then
                        --not selected
                        val2 = frames-1
                      else
                        --selected
                        val2 = 0
                      end
                    else
                      val2 = F_limit(nz(strips[tracks[track_select].strip][page].controls[i].cycledata.pos,0),0,frames-1)
                      if strips[tracks[track_select].strip][page].controls[i].cycledata and 
                         strips[tracks[track_select].strip][page].controls[i].cycledata[nz(strips[tracks[track_select].strip][page].controls[i].cycledata.pos,0)] then
                        DVOV = nz(strips[tracks[track_select].strip][page].controls[i].cycledata[nz(strips[tracks[track_select].strip][page].controls[i].cycledata.pos,0)].dispval,'')
                      end
                    end
                  else
                    if strips[tracks[track_select].strip][page].controls[i].cycledata and 
                       strips[tracks[track_select].strip][page].controls[i].cycledata[nz(strips[tracks[track_select].strip][page].controls[i].cycledata.pos,0)] then
                      DVOV = nz(strips[tracks[track_select].strip][page].controls[i].cycledata[nz(strips[tracks[track_select].strip][page].controls[i].cycledata.pos,0)].dispval,'')
                    end                  
                  end
                elseif ctltype == 6 then
                  --mem button
                  if strips[tracks[track_select].strip][page].controls[i].membtn == nil then
                    strips[tracks[track_select].strip][page].controls[i].membtn = {state = false, mem = 0}
                  end
                  local v3 = GetParamValue_Ctl(i)--strips[tracks[track_select].strip][page].controls[i].val
                  --if tostring(v3) ~= tostring(strips[tracks[track_select].strip][page].controls[i].defval) then
                  local dv = round(math.abs(v3-strips[tracks[track_select].strip][page].controls[i].defval),6)
                    --DBG(dv)  
                  if dv > 0 then
                    strips[tracks[track_select].strip][page].controls[i].membtn = {state = false, mem = v3}
                  else
                    strips[tracks[track_select].strip][page].controls[i].membtn.state = true
                  end
                  if strips[tracks[track_select].strip][page].controls[i].membtn.state == true then
                    val2 = frames-1
                  else
                    val2 = 0                
                  end
                end
                
                if not found then
                  gfx.a = 0.2
                end
  
                if ctlcat == ctlcats.fxparam then
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
                    if dvoff and dvoff ~= 0 then
                      Disp_ParamV = dvaloffset(Disp_ParamV, strips[tracks[track_select].strip][page].controls[i].dvaloffset)  
                    end
                    if maxdp > -1 then
                      Disp_ParamV = roundX(Disp_ParamV, maxdp)                  
                    end
                  end
                elseif ctlcat == ctlcats.trackparam or ctlcat == ctlcats.tracksend then
                  if nz(ctlnmov,'') == '' then
                    Disp_Name = pname
                  else
                    Disp_Name = ctlnmov                  
                  end
                  Disp_ParamV = GetParamDisp(ctlcat, tnum, nil, param, dvoff, i)
                  if maxdp > -1 then
                    Disp_ParamV = roundX(Disp_ParamV, maxdp)                  
                  end                  
                end

                if ctltype == 4 and DVOV and DVOV ~= '' and cycle_editmode == false then
                  if strips[tracks[track_select].strip][page].controls[i].cycledata.posdirty == false then 
                  Disp_ParamV = DVOV
                  end
                end

              local mid = x+(w/2)

              local text_len1x, text_len1y = gfx.measurestr(Disp_Name)
              local text_len2x, text_len2y = gfx.measurestr(Disp_ParamV)

              local xywh1 = {x = math.floor(mid-(text_len1x/2)), y = math.floor(y+(h/2)-toff-1), w = text_len1x, h = th_a+2}
              local xywh2 = {x = math.floor(mid-(text_len2x/2)), y = math.floor(y+(h/2)-to+toff+toffv-1), w = text_len2x, h = th_a+2}
              
              local tl1 = nz(strips[tracks[track_select].strip][page].controls[i].tl1,text_len1x)
              local tl2 = nz(strips[tracks[track_select].strip][page].controls[i].tl2,text_len2x)
              local tx1, tx2, th = math.floor(mid-(tl1/2)),
                                   math.floor(mid-(tl2/2)),th_a --gui.fontsz_knob+tsz-4
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

              if ctlcat == ctlcats.fxparam and not reaper.TrackFX_GetEnabled(track, fxnum) and pname ~= 'Bypass' then
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
              
              if mode == 1 and submode == 2 then
                if tnum and tnum ~= tracks[track_select].tracknum then
                
                  gfx.a = 0.8
                  f_Get_SSV(gui.color.red)
                  gfx.circle(x,y,2,1,1)              
                
                end
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

  function CalcGFXSelRect()

    if strips and tracks[track_select] and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page] then
      if #strips[tracks[track_select].strip][page].graphics > 0 then

        local i = gfx2_select
        local x = strips[tracks[track_select].strip][page].graphics[i].x 
        local y = strips[tracks[track_select].strip][page].graphics[i].y
        local w = strips[tracks[track_select].strip][page].graphics[i].stretchw
        local h = strips[tracks[track_select].strip][page].graphics[i].stretchh
        local rx, ry = x+w, y+h
        local selrect = {x = x-4, y = y-4, w = w+8, h = h+8}
        return selrect
      end
    end

    return nil
      
  end
  
  ------------------------------------------------------------
  
    function GUI_DrawParamLearn(obj, gui)
    
      gfx.a=1
      f_Get_SSV(gui.color.black)
      gfx.rect(obj.sections[115].x,
               obj.sections[115].y, 
               obj.sections[115].w,
               obj.sections[115].h, 1, 1)
      f_Get_SSV('64 64 64')
      gfx.rect(obj.sections[115].x,
               obj.sections[115].y, 
               obj.sections[115].w,
               obj.sections[115].h, 0, 1)
      
      xywh = {x = obj.sections[115].x,
              y = obj.sections[115].y,
              w = obj.sections[115].w,
              h = butt_h}
      
      f_Get_SSV(gui.color.white)
      gfx.a = 1 
      gfx.rect(xywh.x,
               xywh.y, 
               xywh.w,
               butt_h, 1 )
      
      GUI_textC(gui,xywh,'PARAM LEARN',gui.color.black,-2)
      
      xywh.y = obj.sections[116].y
      local iidx = 1023
      
      if knob_select > -1 then
        if ctl_files[knob_select].imageidx ~= nil then
          iidx = ctl_files[knob_select].imageidx
        else
          gfx.loadimg(1023, controls_path..ctl_files[knob_select].fn)
        end
        local w, _ = gfx.getimgdim(iidx)
        gfx.a = 1
        local sx,sy = 1,1
        if w > obj.sections[115].w then
          sx = obj.sections[115].w/w
        end
        if ctl_files[knob_select].cellh > 128 then
          sy = 128/ctl_files[knob_select].cellh
        end
        local sc = F_limit(math.min(sx, sy),0,1)
        gfx.blit(iidx,sc,0, 0, 
                            ctl_files[knob_select].cellh*math.floor(ctl_files[knob_select].frames*0.75), 
                            w, 
                            ctl_files[knob_select].cellh, xywh.x + (xywh.w/2-(w*sc)/2), 
                            xywh.y + (62.5 - (ctl_files[knob_select].cellh*sc)/2))
        
      end
      
      if last_touch_fx then
      
        GUI_textsm_LJ(gui,obj.sections[117],last_touch_fx.tracknum..': '..last_touch_fx.trname,gui.color.white,-5,obj.sections[117].w)
        GUI_textsm_LJ(gui,obj.sections[118],last_touch_fx.fxname,gui.color.white,-5,obj.sections[117].w)
        GUI_textsm_LJ(gui,obj.sections[119],last_touch_fx.prname,gui.color.white,-5,obj.sections[117].w)    
      
      end
      
    end
    
  ------------------------------------------------------------

  function GUI_DrawSnapshots(obj, gui)
    
    gfx.dest = 1003
    
    gfx.a=1
    f_Get_SSV(gui.color.black)
    gfx.rect(0,
             0, 
             obj.sections[160].w,
             obj.sections[160].h, 1, 1)
    f_Get_SSV('64 64 64')
    gfx.rect(0,
             0, 
             obj.sections[160].w,
             obj.sections[160].h, 0, 1)
    
    xywh = {x = 0,
            y = 0,
            w = obj.sections[160].w,
            h = butt_h}
    
    f_Get_SSV(gui.color.white)
    gfx.a = 1 
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             butt_h, 1 )
    gfx.rect(obj.sections[165].x,
             obj.sections[165].y, 
             obj.sections[165].w,
             obj.sections[165].h, 1 )
    
    GUI_textC(gui,xywh,'SNAPSHOTS',gui.color.black,-2)
    
    GUI_DrawButton(gui, '', obj.sections[161], gui.color.white, gui.color.black, true, '', false)
    GUI_DrawButton(gui, 'CAPTURE', obj.sections[162], gui.color.white, gui.color.black, true, '', false)
    
    xywh = {x = obj.sections[163].x,
            y = obj.sections[163].y,
            w = obj.sections[163].w,
            h = obj.sections[163].h}
    f_Get_SSV('64 64 64')
    gfx.a = 1 
    gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 0 )
    
    
    xywh.h = butt_h
    gfx.rect(xywh.x,
     xywh.y, 
     xywh.w,
     xywh.h, 1 )
    gfx.a = 0.5
    f_Get_SSV(gui.color.black)
    gfx.a = 1
    gfx.rect(xywh.x+xywh.w/2,
     xywh.y, 
     2,
     xywh.h, 1 )
    gfx.triangle(xywh.x+xywh.w/4,xywh.y+4,xywh.x+xywh.w/4-6,xywh.y+xywh.h-4,xywh.x+xywh.w/4+6,xywh.y+xywh.h-4,1)     
    gfx.triangle(xywh.x+xywh.w*0.75,xywh.y+xywh.h-4,xywh.x+xywh.w*0.75-6,xywh.y+4,xywh.x+xywh.w*0.75+6,xywh.y+4,1)
    
    gfx.a = 1
    
    SS_butt_cnt = math.floor(obj.sections[163].h / butt_h) - 1
    
    local strip = tracks[track_select].strip
    if strip and snapshots and snapshots[strip] and snapshots[strip][page][sstype_select] then
      if #snapshots[strip][page][sstype_select] > 0 then
        for i = 1,SS_butt_cnt do
        
          xywh.y = obj.sections[163].y + i*butt_h
          local c = gui.color.white
          if ss_select == ssoffset+i then
            f_Get_SSV(gui.color.white)
            gfx.rect(xywh.x,
             xywh.y, 
             xywh.w,
             xywh.h, 1 )
            c = gui.color.black
          end
          if snapshots[strip][page][sstype_select][i+ssoffset] then
            GUI_textsm_LJ(gui,xywh,roundX(i+ssoffset,0)..': '..snapshots[strip][page][sstype_select][i+ssoffset].name,c,-2,xywh.w)
          end
      
        end
    
      end
    end
    
    
    
    gfx.dest = 1    
  end
  
  ------------------------------------------------------------
  
  function GUI_draw(obj, gui)
    gfx.mode =4
    
    if update_gfx or update_surface or update_sidebar or update_topbar or update_ctlopts or update_ctls or update_bg or update_settings or update_snaps or update_msnaps then    
      local p = 0
        
      gfx.dest = 1
      if update_gfx then
        gfx.setimgdim(1, -1, -1)  
        gfx.setimgdim(1, gfx1.main_w,gfx1.main_h)
      end
            
      if resize_display then
        gfx.setimgdim(1002,obj.sections[45].w, obj.sections[45].h)
        gfx.setimgdim(1003,obj.sections[160].w, obj.sections[160].h)
      elseif resize_snaps then
        gfx.setimgdim(1003,obj.sections[160].w, obj.sections[160].h)      
      end
      
      if mode == 0 then
        --Live
        if update_gfx or (surface_size.limit == false and update_surface) then
          GUI_DrawControlBackG(obj, gui)
          GUI_DrawControls(obj, gui)
          if show_snapshots then
            GUI_DrawSnapshots(obj, gui)
          end
        elseif update_snaps or (update_msnaps and resize_snaps) then        
          GUI_DrawSnapshots(obj, gui)
        elseif update_ctls then        
          GUI_DrawControls(obj, gui)
        end
        if update_gfx or update_sidebar then        
          GUI_DrawTracks(obj, gui)
        end
        
        gfx.dest = 1
        
        if update_gfx or update_surface or update_bg or update_msnaps then
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
          gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)
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
        
        if show_snapshots then
        --DBG(obj.sections[160].x..'  '..obj.sections[160].y..'  '..obj.sections[160].w..'  '..obj.sections[160].h)
          gfx.blit(1003,1,0,0,0,obj.sections[160].w,obj.sections[160].h,obj.sections[160].x,obj.sections[160].y)        
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
          --gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h+2)
          
          if ctl_select ~= nil then
            selrect = CalcSelRect()
            if selrect then
              f_Get_SSV(gui.color.yellow)
              gfx.a = 1
              gfx.roundrect(selrect.x - surface_offset.x + obj.sections[10].x, selrect.y - surface_offset.y + obj.sections[10].y, selrect.w, selrect.h, 8, 1, 0)
            end
          end
                    
          gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h+2)
          
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
          
          if update_gfx or update_surface then
            if lockh > 0 or lockw > 0 then
              UpdateLEdges()
            end
          end
                    
          if show_ctloptions and ctl_select ~= nil then
            
            local w,h = gfx.getimgdim(1021)
            gfx.a = 0.5
            gfx.blit(1021,1,0,0,0,w,h,obj.sections[60].x,obj.sections[60].y)
            GUI_DrawCtlOptions(obj, gui)
            if show_cycleoptions then
              GUI_DrawCycleOptions(obj, gui)
            end            
          end
          
          if show_paramlearn and fxmode == 0 then
            GUI_DrawParamLearn(obj,gui)
          end        

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
          
          --gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)

          if draggfx ~= nil then
            local x, y = draggfx.x, draggfx.y
            local w, h = gfx.getimgdim(1023)
            gfx.a = 0.5
            
            gfx.blit(1023,1,0,0,0,w,h,x,y)          
          end

          if gfx2_select ~= nil then
          
            selrect = CalcGFXSelRect()
            if selrect then
              if poslock_select == true then
                f_Get_SSV(gui.color.red)
              else
                f_Get_SSV(gui.color.yellow)
              end
              gfx.a = 1
              selrect.x = selrect.x - surface_offset.x + obj.sections[10].x
              selrect.y = selrect.y - surface_offset.y + obj.sections[10].y
              
              gfx.roundrect(selrect.x, selrect.y, selrect.w, selrect.h, 8, 1, 0)
              if show_lbloptions == false then
                gfx.circle(selrect.x+selrect.w,selrect.y+selrect.h/2,4,1,1)
                gfx.circle(selrect.x+selrect.w,selrect.y+selrect.h,4,1,1)
                gfx.circle(selrect.x+selrect.w/2,selrect.y+selrect.h,4,1,1)              
              end
            end            
          
          end
          gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)

          if show_lbloptions and gfx2_select ~= nil then            
            GUI_DrawLblOptions(obj, gui)
          end

          if update_gfx or update_surface then
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
          --gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)          
          
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

          gfx.blit(1001,1,0,0,0,obj.sections[43].w,obj.sections[43].h,0,butt_h)          

          gfx.a=1
          f_Get_SSV(gui.color.white)
          gfx.rect(obj.sections[15].x,
                   obj.sections[15].y, 
                   obj.sections[15].w,
                   obj.sections[15].h, 1, 1)
          GUI_textC(gui,obj.sections[15],'SAVE STRIP',gui.color.black,-2)        

          if update_gfx or update_surface then
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
      
      --if update_surfaceedge then
      --  UpdateEdges()
      --end
      
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
    update_snaps = false
    update_msnaps = false
    resize_snaps = false
    
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
               obj.sections[13].w-1,
               obj.sections[13].h, 1, 1)
      if mode == 1 and submode == 0 then
        local xywh = {x = obj.sections[13].x,
                      y = obj.sections[13].y, 
                      w = obj.sections[13].x+obj.sections[13].w-30,
                      h = obj.sections[13].h}
        if fxmode == 0 then
          GUI_textsm_CJ(gui,xywh,submode_table[submode+1],gui.color.black,-2,xywh.w)
        elseif fxmode == 1 then
          GUI_textsm_CJ(gui,xywh,'TR PARAMS',gui.color.black,-2,xywh.w) --hardcoded - sort out eventually
        end
      else
        GUI_textC(gui,obj.sections[13],submode_table[submode+1],gui.color.black,-2)
      end
      if submode == 0 then
        f_Get_SSV(gui.color.black)
        local xywh = {x = obj.sections[13].x+obj.sections[13].w - 30,
                      y = obj.sections[13].y, 
                      w = 30,
                      h = obj.sections[13].h}
        gfx.rect(xywh.x,
                 xywh.y, 
                 2,
                 xywh.h, 1, 1)
        GUI_textC(gui,xywh,'*',gui.color.black,-2)

--[[        local xywh = {x = obj.sections[13].x,
                      y = obj.sections[13].y, 
                      w = 30,
                      h = obj.sections[13].h}
        if trackedit_select ~= track_select then
          f_Get_SSV(gui.color.red)
          gfx.rect(xywh.x,
                   xywh.y, 
                   xywh.w,
                   xywh.h, 1, 1)        
        end
        f_Get_SSV(gui.color.black)
        gfx.rect(xywh.x+xywh.w,
                 xywh.y, 
                 2,
                 xywh.h, 1, 1)
        if trackedit_select >= 0 then
          GUI_textC(gui,xywh,'Tr'..trackedit_select,gui.color.black,-2)
        else
          GUI_textC(gui,xywh,'Mst',gui.color.black,-2)        
        end]]                 
      end
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

    f_Get_SSV(gui.color.white)
    gfx.rect(obj.sections[21].x,
             obj.sections[21].y, 
             obj.sections[21].w,
             obj.sections[21].h, 1, 1)
    GUI_textC(gui,obj.sections[21],'...',gui.color.black,-2)
    if obj.sections[17].x > obj.sections[20].x+obj.sections[20].w then
      f_Get_SSV(gui.color.white)
      gfx.rect(obj.sections[17].x,
               obj.sections[17].y, 
               obj.sections[17].w,
               obj.sections[17].h, 1, 1)
      GUI_textC(gui,obj.sections[17],'SAVE',gui.color.black,-2)
    else
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
  
    local ww = gfx1.main_w - (plist_w)
    local bw = F_limit((obj.sections[10].w / surface_size.w),0,1)*(ww-4)
    local bx = F_limit(F_limit(((surface_offset.x) / surface_size.w),0,1)*(ww-4),0,ww-4-bw)

    local hh = gfx1.main_h - (butt_h+2)
    local bh = F_limit((obj.sections[10].h / surface_size.h),0,1)*(hh-4)
    local by = F_limit(F_limit(((surface_offset.y) / surface_size.h),0,1)*(hh-4),0,hh-4-bh)

    local xywh = {x = plist_w,
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
                  w = sb_size+4,
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

    local xywh = {x = (plist_w+2),
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
    GUI_DrawTick(gui, 'Disable send checks', obj.sections[72], gui.color.white, settings_disablesendchecks)             
    GUI_DrawTick(gui, 'Save all track fx with strip', obj.sections[73], gui.color.white, settings_saveallfxinststrip)
    GUI_DrawSliderH(gui, 'Control refresh rate', obj.sections[74], gui.color.black, gui.color.white, (1-(settings_updatefreq*10)))
    GUI_DrawTick(gui, 'Lock control window width', obj.sections[75], gui.color.white, lockx)
    GUI_DrawTick(gui, 'Lock control window height', obj.sections[76], gui.color.white, locky)
    GUI_DrawButton(gui, lockw, obj.sections[77], gui.color.white, gui.color.black, lockx)
    GUI_DrawButton(gui, lockh, obj.sections[78], gui.color.white, gui.color.black, locky)
    
    GUI_DrawTick(gui, 'Show grid / grid size', obj.sections[80], gui.color.white, settings_showgrid)
    GUI_DrawButton(gui, settings_gridsize, obj.sections[79], gui.color.white, gui.color.black, true)
    GUI_DrawTick(gui, 'Can mousewheel on knob', obj.sections[81], gui.color.white, settings_mousewheelknob)
               
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
        
        xx = obj.sections[10].x + obj.sections[10].w
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
        
        yy = obj.sections[10].y + obj.sections[10].h
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

  function GetParamDisp_Ctl(c)
    local t = strips[tracks[track_select].strip].track.tracknum
    if strips[tracks[track_select].strip][page].controls[c].tracknum ~= nil then
      t = strips[tracks[track_select].strip][page].controls[c].tracknum
    end
    
    local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat
    if cc == ctlcats.fxparam then
      local f = strips[tracks[track_select].strip][page].controls[c].fxnum
      local p = strips[tracks[track_select].strip][page].controls[c].param
      local dvoff = strips[tracks[track_select].strip][page].controls[c].dvaloffset
      local dval = GetParamDisp(cc, t, f, p, dvoff,c)
      return dval
      
    elseif cc == ctlcats.trackparam then
      local p = strips[tracks[track_select].strip][page].controls[c].param    
      local dvoff = strips[tracks[track_select].strip][page].controls[c].dvaloffset
      local dval = GetParamDisp(cc, t, nil, p, dvoff,c)
      return dval

    elseif cc == ctlcats.tracksend then
      local p = strips[tracks[track_select].strip][page].controls[c].param    
      local dvoff = strips[tracks[track_select].strip][page].controls[c].dvaloffset
      local dval = GetParamDisp(cc, t, nil, p, dvoff,c)
      return dval
    end
    
  end
    
  function GetParamDisp(ctlcat,tracknum,fxnum,paramnum, dvoff,c)
    track = GetTrack(tracknum)
    if ctlcat == ctlcats.fxparam then
      local _, d = reaper.TrackFX_GetFormattedParamValue(track, fxnum, paramnum, "")
      if dvoff then
        d = dvaloffset(d, dvoff)
      end
      return d

    elseif ctlcat == ctlcats.trackparam then
      local d
      if paramnum == 1 then
        --volume
        d = reaper.mkvolstr('', reaper.GetMediaTrackInfo_Value(track, trctls_table[paramnum].parmname))
      elseif paramnum == 2 or paramnum == 4 or paramnum == 5 then
        --pan
        d = reaper.mkpanstr('', reaper.GetMediaTrackInfo_Value(track, trctls_table[paramnum].parmname))
      else
        d = round(reaper.GetMediaTrackInfo_Value(track, trctls_table[paramnum].parmname),2)
      end

      if dvoff then
        d = dvaloffset(d, dvoff)
      end
      return d

    elseif ctlcat == ctlcats.tracksend then
      local d
      local paramidx = strips[tracks[track_select].strip][page].controls[c].param_info.paramidx
      local paramstr = strips[tracks[track_select].strip][page].controls[c].param_info.paramstr
      local tidx = ((paramnum-1) % 3) +1
      if paramnum % 3 == 1 then
        --volumes
        --d = reaper.mkvolstr('', reaper.GetTrackSendInfo_Value(track, 0, paramidx, paramstr))
        retval, vOut, pOut = reaper.GetTrackSendUIVolPan(track, paramidx)
        d = reaper.mkvolstr('', vOut)
      elseif paramnum % 3 == 2 then
        --pan
        --d = reaper.mkpanstr('', reaper.GetTrackSendInfo_Value(track, 0, paramidx, paramstr))
        retval, vOut, pOut = reaper.GetTrackSendUIVolPan(track, paramidx)
        d = reaper.mkpanstr('', pOut)
      else
        d = round(reaper.GetTrackSendInfo_Value(track, 0, paramidx, paramstr),2)
      end

      if dvoff then
        d = dvaloffset(d, dvoff)
      end
      return d
    end
  end

  function GetParamValue_Ctl(c)
    if c then
      local t = strips[tracks[track_select].strip].track.tracknum
      if strips[tracks[track_select].strip][page].controls[c].tracknum ~= nil then
        t = strips[tracks[track_select].strip][page].controls[c].tracknum
      end
      local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat
      if cc == ctlcats.fxparam then
        local f = strips[tracks[track_select].strip][page].controls[c].fxnum
        local p = strips[tracks[track_select].strip][page].controls[c].param
        track = GetTrack(t)
        
        local v, min, max = reaper.TrackFX_GetParam(track, f, p)
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end
        return normalize(min, max, v)

      elseif cc == ctlcats.trackparam then
        local p = strips[tracks[track_select].strip][page].controls[c].param
        local min, max = GetParamMinMax(cc,nil,nil,p,true,c)
        return GMTI_norm(track, p, min, max)

      elseif cc == ctlcats.tracksend then
        local p = strips[tracks[track_select].strip][page].controls[c].param
        local min, max = GetParamMinMax(cc,nil,nil,p,true,c)
        return GTSI_norm(track, p, min, max,c)
      end
    else
      return 0
    end
  end
  
  function GMTI_norm(track,trctl_idx,min,max)
  
    return normalize(min,max,reaper.GetMediaTrackInfo_Value(track, trctls_table[trctl_idx].parmname))
  
  end

  function GTSI_norm(track,trctl_idx,min,max,c)

    local idx = strips[tracks[track_select].strip][page].controls[c].param_info.paramidx
    local paramstr = strips[tracks[track_select].strip][page].controls[c].param_info.paramstr

    if track == nil then
      track = GetTrack(nz(strips[tracks[track_select].strip][page].controls[c].tracknum,strips[tracks[track_select].strip].track.tracknum))
    end
    
    if paramstr == 'D_VOL' then
      retval, vOut, pOut = reaper.GetTrackSendUIVolPan(track, idx)
      return normalize(min, max, vOut)
    elseif paramstr == 'D_PAN' then
      retval, vOut, pOut = reaper.GetTrackSendUIVolPan(track, idx)
      return normalize(min, max, pOut)
    else    
      return normalize(min,max,reaper.GetTrackSendInfo_Value(track, 0, idx, paramstr))
    end
    
  end

  function SMTI_norm(track,trctl_idx,v,min,max)
  
    local val = DenormalizeValue(min,max,v)
    reaper.SetMediaTrackInfo_Value(track, trctls_table[trctl_idx].parmname, val)
    
  end

  function SMTI_denorm(track,trctl_idx,v)
  
      reaper.SetMediaTrackInfo_Value(track, trctls_table[trctl_idx].parmname, v)

  end

  function STSI_norm(track,trctl_idx,v,min,max,c)
  
    local idx = strips[tracks[track_select].strip][page].controls[c].param_info.paramidx
    local paramstr = strips[tracks[track_select].strip][page].controls[c].param_info.paramstr

    local val = DenormalizeValue(min,max,v)
    if paramstr == 'D_VOL' then
      reaper.SetTrackSendUIVol(track, idx, val, -1)
    elseif paramstr == 'D_PAN' then
      reaper.SetTrackSendUIPan(track, idx, val, -1)
    else
      reaper.SetTrackSendInfo_Value(track, 0, idx, paramstr, val)
    end
  end

  function STSI_denorm(track,trctl_idx,val,c)
  
    local idx = strips[tracks[track_select].strip][page].controls[c].param_info.paramidx
    local paramstr = strips[tracks[track_select].strip][page].controls[c].param_info.paramstr

    if paramstr == 'D_VOL' then
      reaper.SetTrackSendUIVol(track, idx, val, -1)
    elseif paramstr == 'D_PAN' then
      reaper.SetTrackSendUIPan(track, idx, val, -1)
    else
      reaper.SetTrackSendInfo_Value(track, 0, idx, paramstr, val)
    end
  end
    
  function GetParamValue(ctlcat,tracknum,fxnum,paramnum,c)
    track = GetTrack(tracknum)
    if ctlcat == ctlcats.fxparam then
      local v, min, max = reaper.TrackFX_GetParam(track, fxnum, paramnum)
      if c then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end
      end
      return normalize(min, max, v)

    elseif ctlcat == ctlcats.trackparam then
      local min, max = GetParamMinMax(ctlcat,nil,nil,paramnum,true,c)
      return GMTI_norm(track, paramnum, min, max)

    elseif ctlcat == ctlcats.tracksend then
      local min, max = GetParamMinMax(ctlcat,nil,nil,paramnum,true,c)
      return GTSI_norm(track, paramnum, min, max,c)
    end
  end

  function GetParamValue2(ctlcat,track,fxnum,paramnum,c)
    if ctlcat == ctlcats.fxparam then
      local v, min, max = reaper.TrackFX_GetParam(track, fxnum, paramnum)
      if c then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end
      end  
      return normalize(min, max, v)

    elseif ctlcat == ctlcats.trackparam then
      local min, max = GetParamMinMax(ctlcat,nil,nil,paramnum,true,c)
      return GMTI_norm(track, paramnum, min, max)

    elseif ctlcat == ctlcats.tracksend then
      local min, max = GetParamMinMax(ctlcat,nil,nil,paramnum,true,c)
      return GTSI_norm(track, paramnum, min, max,c)
    end
  end
  
  function GetParamMinMax(ctlcat,track,fxnum,paramnum,checkov,c)
    if ctlcat == ctlcats.fxparam then    
      if track == nil then return end
      local _, min, max = reaper.TrackFX_GetParam(track, fxnum, paramnum)
      if checkov and checkov == true and c then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end      
      end
      return min, max  
    
    elseif ctlcat == ctlcats.trackparam then
      local min, max = trctls_table[paramnum].min, trctls_table[paramnum].max
      if checkov and checkov == true and c then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end      
      end
      return tonumber(min), tonumber(max)  
      
    elseif ctlcat == ctlcats.tracksend then
      local idx = math.floor((paramnum-1) % 3)+1
      local min, max = trsends_mmtable[idx].min, trsends_mmtable[idx].max
      if checkov and checkov == true and c then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end      
      end
      return tonumber(min), tonumber(max)  
    end
  end

  function GetParamMinMax_ctlselect()
    if ctl_select and #ctl_select >= 1 then
      trackfxparam_select = ctl_select[1].ctl
      local track
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum == nil then
        track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      else
        track = GetTrack(strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum)
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat 
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum      
        local paramnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        
        local _, min, max = reaper.TrackFX_GetParam(track, fxnum, paramnum)
        return min, max
      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        return tonumber(trctls_table[param].min), tonumber(trctls_table[param].max)
      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        local idx = math.floor((param-1) % 3)+1
        return tonumber(trsends_mmtable[idx].min), tonumber(trsends_mmtable[idx].max)
      end
    else
      return nil, nil
    end
  end
  
  function GetParamMinMax_ctl(c, checkov)
    
    if checkov == nil then checkov = true end
    
    local t = strips[tracks[track_select].strip].track.tracknum
    if strips[tracks[track_select].strip][page].controls[c].tracknum ~= nil then
      t = strips[tracks[track_select].strip][page].controls[c].tracknum
    end

    local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat 
    if cc == ctlcats.fxparam then
      local f = strips[tracks[track_select].strip][page].controls[c].fxnum
      local p = strips[tracks[track_select].strip][page].controls[c].param
      local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat
      
      local track = GetTrack(t)
      local min, max = GetParamMinMax(cc,track,nz(f,-1),p,checkov,c)
      return min, max

    elseif cc == ctlcats.trackparam then
      local param = strips[tracks[track_select].strip][page].controls[c].param
      local min, max = trctls_table[param].min, trctls_table[param].max
      if checkov then    
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end
      end
      return tonumber(min), tonumber(max)

    elseif cc == ctlcats.tracksend then
      local param = strips[tracks[track_select].strip][page].controls[c].param
      local idx = math.floor((param-1) % 3)+1
      local min, max = trsends_mmtable[idx].min, trsends_mmtable[idx].max
      if checkov then
        if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end      
      end
      return tonumber(min), tonumber(max)  
    end
  end
  
  function normalize(min, max, val)
    return (val - min)/(max - min)
  end
  
  --nv*(max - min) + min = val
  function DenormalizeValue(min, max, val)
    return val*(max - min) + min
  end
  
  ------------------------------------------------------------
  
  function SetParam()
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      local val = strips[tracks[track_select].strip][page].controls[trackfxparam_select].val
      local track 
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum == nil then
        track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      else
        track = GetTrack(strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum)
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nz(fxnum,-1),param,true,trackfxparam_select)
        reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, DenormalizeValue(min, max, val))

      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        SMTI_norm(track,param,val,min,max)

      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        STSI_norm(track,param,val,min,max,trackfxparam_select)
      end
    end
      
  end
  
------------------------------------------------------------
  
  function SetParam2(force)
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      local val = strips[tracks[track_select].strip][page].controls[trackfxparam_select].val
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum == nil then
        track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      else
        track = GetTrack(strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum)
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        --local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nz(fxnum,-1),param,true,trackfxparam_select)
        if force and force == true then
          reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, DenormalizeValue(min, max, 1-math.abs(val-0.1)))
        end
        reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, DenormalizeValue(min, max, val))

      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        if force and force == true then
          SMTI_norm(track,param,1-math.abs(val-0.1),min,max)
        end      
        SMTI_norm(track,param,val,min,max)

      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        if force and force == true then
          STSI_norm(track,param,1-math.abs(val-0.1),min,max,trackfxparam_select)
        end      
        STSI_norm(track,param,val,min,max,trackfxparam_select)
      end
    end
      
  end

------------------------------------------------------------
  
  function SetParam3(v)
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum == nil then
        track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      else
        track = GetTrack(strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum)
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        local min, max = GetParamMinMax(cc,track,nz(fxnum,-1),param,true,trackfxparam_select)
        reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, DenormalizeValue(min, max, v))

      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        SMTI_norm(track,param,v,min,max)

      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        local min, max = GetParamMinMax(cc,track,nil,param,true,trackfxparam_select)
        STSI_norm(track,param,v,min,max,trackfxparam_select)
      end    
    end
      
  end

  function SetParam3_Denorm(trnum, v)
  
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      local track = GetTrack(trnum)
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, v)

      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        SMTI_denorm(track,param,v)

      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        STSI_denorm(track,param,v,trackfxparam_select)
      end    
    end
      
  end
  
  function SetParam4(v)
    
    if strips and strips[tracks[track_select].strip] and strips[tracks[track_select].strip][page].controls[trackfxparam_select] then
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum == nil then
        track = GetTrack(strips[tracks[track_select].strip].track.tracknum)
      else
        track = GetTrack(strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum)
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      if cc == ctlcats.fxparam then
        local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
        local min, max = GetParamMinMax(cc,track,nz(fxnum,-1),param)
        reaper.TrackFX_SetParam(track, nz(fxnum,-1), param, DenormalizeValue(min, max, v))

      elseif cc == ctlcats.trackparam then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        --local min, max = trctls_table[param].min,trctls_table[param].max
        SMTI_norm(track,param,v,0,1)

      elseif cc == ctlcats.tracksend then
        local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        --local min, max = trctls_table[param].min,trctls_table[param].max
        STSI_norm(track,param,v,0,1,trackfxparam_select)
      end        
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
      
      Snapshots_Check(tracks[track_select].strip,page)
      
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

  function EditSSName(eb)
  
    local sizex,sizey = 400,200
    editbox={title = 'Please enter new snapshot name:',
      x=400, y=100, w=120, h=20, l=4, maxlen=20,
      fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
      txtcol=0x000000, curscol=0x000000,
      font=1, fontsz=14, caret=0, sel=0, cursstate=0,
      text="", 
      hasfocus=true
    }
    
    EB_Open = eb  
  
  end

  function EditSSName2(txt)

    if ss_select and snapshots and snapshots[tracks[track_select].strip] and snapshots[tracks[track_select].strip][page][sstype_select][ss_select] then
      snapshots[tracks[track_select].strip][page][sstype_select][ss_select].name = txt
    end
  end
  
  function DeleteSS()
  
    if ss_select and snapshots and snapshots[tracks[track_select].strip] and snapshots[tracks[track_select].strip][page][sstype_select][ss_select] then
    
      local cnt = #snapshots[tracks[track_select].strip][page][sstype_select]
      snapshots[tracks[track_select].strip][page][sstype_select][ss_select] = nil
      local tbl = {}
      for i = 1, cnt do
        if snapshots[tracks[track_select].strip][page][sstype_select][i] ~= nil then
          table.insert(tbl, snapshots[tracks[track_select].strip][page][sstype_select][i])
        end
      end
      snapshots[tracks[track_select].strip][page][sstype_select] = tbl
      ss_select = nil
      
    end
    
  end
  
  ------------------------------------------------------------    

  function EditValue(eb)
  
    local sizex,sizey = 400,200
    editbox={title = 'Please enter value:',
      x=400, y=100, w=120, h=20, l=4, maxlen=20,
      fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
      txtcol=0x000000, curscol=0x000000,
      font=1, fontsz=14, caret=0, sel=0, cursstate=0,
      text="", 
      hasfocus=true
    }
    
    EB_Open = eb  
  
  end

  function EditValue2(txt)

    if strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctltype == 4 then
      --cycle
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata.statecnt > 0 then
        for i = 1, strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata.statecnt do
        
          if string.upper(txt) == string.sub(string.upper(strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata[i].dispval),1,string.len(txt)) then
          
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata.pos = i
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].val = 
                strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata[i].val
            SetParam()
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
            update_ctls = true
            break
          end
        
        end
      
      end
    else
      local mo = tonumber(txt)
      if mo then
        local nval = GetValFromDVal(trackfxparam_select,txt)
        --for i = 1, #ctl_select do 
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].val = nval
        strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
        SetParam()
        --end
      end  
    end
  end

  function EditCycleDV(txt)

    cycle_select[cycle_select.selected].dispval = txt

  end

  function EditMinDVal()
  
    local sizex,sizey = 400,200
    editbox={title = 'Please enter a min value:',
      x=400, y=100, w=120, h=20, l=4, maxlen=20,
      fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
      txtcol=0x000000, curscol=0x000000,
      font=1, fontsz=14, caret=0, sel=0, cursstate=0,
      text="", 
      hasfocus=true
    }
    
    EB_Open = 4  
  
  end

  function EditMinDVal2(txt)

    local mo = tonumber(txt)
    if mo then
      local test = GetValFromDVal(ctl_select[1].ctl,txt)
      minov_select = mo
      --for i = 1, #ctl_select do 
      --  strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].minov = mo
      --end
    end  
  end

  function EditDValOffset()
  
    local sizex,sizey = 400,200
    editbox={title = 'Please enter a display offset value:',
      x=400, y=100, w=120, h=20, l=4, maxlen=20,
      fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
      txtcol=0x000000, curscol=0x000000,
      font=1, fontsz=14, caret=0, sel=0, cursstate=0,
      text="", 
      hasfocus=true
    }
    
    EB_Open = 3  
  
  end

  function EditDValOffset2(txt)

    local dv = tonumber(txt)
    if dv then
      dvaloff_select = dv
      for i = 1, #ctl_select do 
        strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dvaloffset = dv
      end
    else
      dvaloff_select = ''
      for i = 1, #ctl_select do 
        strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dvaloffset = nil
      end    
    end  
  end

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
            x=400, y=100, w=120, h=20, l=4, maxlen=40,
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
          --local _, fxname = reaper.TrackFX_GetFXName(tr, i, '')
          local fxchunk = GetChunkPresetData(chunk, i)
          local fxn = GetPlugNameFromChunk(fxchunk)
          fxtbl[i+1] = {fxname = fxn,
                        fxchunk = fxchunk,
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
            --local _, fxname = reaper.TrackFX_GetFXName(tr, i, '')
            local fxchunk = GetChunkPresetData(chunk, i)
            local fxn = GetPlugNameFromChunk(fxchunk)
            fxtbl[fxcnt] = {fxname = fxn,
                            fxchunk = fxchunk,
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
        if savestrip.strip.controls[i].fxguid then
          savestrip.strip.controls[i].fxguid = '{'..savestrip.strip.controls[i].fxguid..'}'
        end
      end

      OpenMsgBox(1,'Strip saved.',1)

    end
    PopulateStrips()
    
  end
  
  function GetPlugNameFromChunk(fxchunk)

    local fxn
    if string.sub(fxchunk,1,3) == 'VST' then
      fxn = string.match(fxchunk, '.*: (.-) %(')
    elseif string.sub(fxchunk,1,2) == 'JS' then
      fxn = string.match(fxchunk, 'JS.*%/+(.-) \"')
      if fxn == nil then
        fxn = string.match(fxchunk, 'JS%s(.-)%s')  -- gets full path of effect
        fxn = string.match(fxn, '([^/]+)$') -- gets filename  
      end
      --remove final " if exists
      if string.sub(fxn,string.len(fxn)) == '"' then
        fxn = string.sub(fxn,1,string.len(fxn)-1)
      end
      
      --[[if fxn == nil then
        --JS \"AB Level Matching JSFX [2.5]/AB_LMLT_cntrl\" \"MSTR /B\"\
        fxn = string.match(fxchunk, 'JS.*%/(.-)%"%\"')
        fxn = string.sub(fxn,1,string.len(fxn)-2)
      end]]
    end
  
    return fxn
    
  end
  
  function GenID()
  
    return math.floor(math.random() * 0xFFFFFFFF)
    
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
  
      local fxn
      if stripdata.fx[i].fxname then
        fxn = stripdata.fx[i].fxname
      else
        fxn = GetPlugNameFromChunk(stripdata.fx[i].fxchunk)
      end
      if fxn then
        retfx = reaper.TrackFX_AddByName(tr, fxn, 0, -1)
      else
        retfx = -1
      end
      
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
    
    --time = math.abs(math.sin( -1 + (os.clock() % 2)))
    stripid = GenID()
    
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
      strips[strip][page].controls[cc].c_id = GenID() --give a new control id
      
      --compatibility
      if strips[strip][page].controls[cc].scalemode == nil then strips[strip][page].controls[cc].scalemode = 8 end
      if strips[strip][page].controls[cc].framemode == nil then strips[strip][page].controls[cc].framemode = 1 end      
      if strips[strip][page].controls[cc].ctlcat == nil then strips[strip][page].controls[cc].ctlcat = ctlcats.fxparam end
      if strips[strip][page].controls[cc].maxdp == nil then strips[strip][page].controls[cc].maxdp = -1 end
      if strips[strip][page].controls[cc].cycledata == nil then
        strips[strip][page].controls[cc].cycledata = {statecnt = 0, {}}
      end
      if strips[strip][page].controls[cc].membtn == nil then
        strips[strip][page].controls[cc].membtn = {state = false, mem = 0}
      end
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
      --compatibility
      if stripdata.strip.graphics[j].stretchw == nil then stripdata.strip.graphics[j].stretchw = w end
      if stripdata.strip.graphics[j].stretchh == nil then stripdata.strip.graphics[j].stretchh = h end      

      if stripdata.strip.graphics[j].gfxtype == nil then stripdata.strip.graphics[j].gfxtype = gfxtype.img end
      if stripdata.strip.graphics[j].font == nil then
        stripdata.strip.graphics[j].font = {idx = nil,
                                            name = nil,
                                            size = nil,
                                            bold = nil,
                                            italics = nil,
                                            underline = nil,
                                            shadow = nil
                                            }
        stripdata.strip.graphics[j].text = nil
        stripdata.strip.graphics[j].text_col = nil
      end
      
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
            maxx = strip.graphics[i].x + strip.graphics[i].stretchw
            maxy = strip.graphics[i].y + strip.graphics[i].stretchh
          else
            minx = math.min(minx, strip.graphics[i].x)
            miny = math.min(miny, strip.graphics[i].y)
            maxx = math.max(maxx, strip.graphics[i].x + strip.graphics[i].stretchw)
            maxy = math.max(maxy, strip.graphics[i].y + strip.graphics[i].stretchh)
          end
          local fnd = false
          for j = 0, #graphics_files do
            if nz(strip.graphics[i].gfxtype,gfxtype.img) == gfxtype.img then
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
        
          if nz(strip.graphics[i].gfxtype, gfxtype.img) == gfxtype.img then

            local x = strip.graphics[i].x+offsetx 
            local y = strip.graphics[i].y+offsety
            local w = strip.graphics[i].w
            local h = strip.graphics[i].h
            local sw = strip.graphics[i].stretchw
            local sh = strip.graphics[i].stretchh
            local imageidx = strip.graphics[i].imageidx
            
            gfx.blit(imageidx,1,0, 0, 0, w, h, x, y, sw, sh)
          
          elseif strip.graphics[i].gfxtype == gfxtype.txt then
          
            local x = strip.graphics[i].x+offsetx 
            local y = strip.graphics[i].y+offsety
          
            local text = strip.graphics[i].text
            local textcol = strip.graphics[i].text_col
            
            local flagb,flagi,flagu = 0,0,0
            if strip.graphics[i].font.bold then flagb = 98 end
            if strip.graphics[i].font.italics then flagi = 105 end
            if strip.graphics[i].font.underline then flagu = 117 end
            local flags = flagb + (flagi*256) + (flagu*(256^2))
            gfx.setfont(1,strip.graphics[i].font.name,
                          strip.graphics[i].font.size,flags)
            if strip.graphics[i].font.shadow then
            
              local shadx = nz(strip.graphics[i].font.shadow_x,1)
              local shady = nz(strip.graphics[i].font.shadow_y,1)
            
              f_Get_SSV(gui.color.black)
              gfx.a = 0.5
              gfx.x, gfx.y = x+shadx,y+shady
              gfx.drawstr(text)
            end
            
            gfx.a = 1
            gfx.x, gfx.y = x,y
            f_Get_SSV(textcol)
            
            gfx.drawstr(text)
          
          end
      
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
            
              local tr2 = tr
              if strips[tracks[track_select].strip][p].controls[c].tracknum ~= nil then
                tr_found = CheckTrack(strips[tracks[track_select].strip][p].controls[c].tracknum,
                                      tracks[track_select].strip, p, c)                      
                if tr_found then
                  tr2 = GetTrack(strips[tracks[track_select].strip][p].controls[c].tracknum)

                  if strips[tracks[track_select].strip][p].controls[c].ctlcat == ctlcats.fxparam then
                    if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr2, nz(strips[tracks[track_select].strip][p].controls[c].fxnum,-1)) then
                      --fx found
                      strips[tracks[track_select].strip][p].controls[c].fxfound = true
                    else
                      --find fx by guid
                      local fx_found = false
                      for f = 0, reaper.TrackFX_GetCount(tr2) do
                        if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr2, f) then
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
                  else
                    --other control type
                  
                  end

                else
                  --track not found
                end              
              else
            
                if strips[tracks[track_select].strip][p].controls[c].ctlcat == ctlcats.fxparam then
                  if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr2, nz(strips[tracks[track_select].strip][p].controls[c].fxnum,-1)) then
                    --fx found
                    strips[tracks[track_select].strip][p].controls[c].fxfound = true
                  else
                    --find fx by guid
                    local fx_found = false
                    for f = 0, reaper.TrackFX_GetCount(tr2) do
                      if strips[tracks[track_select].strip][p].controls[c].fxguid == reaper.TrackFX_GetFXGUID(tr2, f) then
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
                else
                  --other control type
                
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

  function CheckTrack(track, strip, p, c)
  
    if c == nil then
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
    else
      --external track ctl
      if strip and strips[strip] and strips[strip][p] and strips[strip][p].controls[c] then --temp
        local found = false
        local trx = GetTrack(nz(strips[strip][p].controls[c].tracknum,-2))
        if trx then
          if strips[strip][p].controls[c].trackguid == reaper.GetTrackGUID(trx) then
            return true
          else
            --Find track and update tracknum
            for i = 0, reaper.CountTracks(0) do
              local tr = GetTrack(i)
              if tr ~= nil then
                if strips[strip][p].controls[c].trackguid == reaper.GetTrackGUID(tr) then
                  --found
                  found = true
                  strips[strip][p].controls[c].tracknum = i
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
              if strips[strip][p].controls[c].trackguid == reaper.GetTrackGUID(tr) then
                --found
                found = true
                strips[strip][p].controls[c].tracknum = i
                update_gfx = true
                break 
              end
            end
          end    
          PopulateTracks()    
        end
        return found
      else
        return true --temp
      end      
    end
        
  end
  
  ------------------------------------------------------------    

  function testchunk(tr)
    _, statechunk = reaper.GetTrackStateChunk(tr,'',false)
    reaper.ClearConsole()
    
    local fxidx = 1
    local r, s, e = GetChunkPresetData(statechunk,fxidx)
    local t = string.sub(statechunk,s,e)
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
          if string.upper(string.sub(chunk,xe+xs,xe+xs+2)) == 'VST' or string.upper(string.sub(chunk,xe+xs,xe+xs+2)) == 'JS ' then
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
  
  function GFXMenu()
    local mstr
    if gfx2_select then
      local mm = '#Copy formatting|#Paste formatting'
      if strips[tracks[track_select].strip][page].graphics[gfx2_select].gfxtype == gfxtype.txt then
        mm = 'Copy formatting|Paste formatting'
      end
      local mm2 = 'Lock position'
      if nz(strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock,false) == true then
        mm2 = '!'..mm2
      end
      mstr = 'Move up|Move down|Bring to front|Send to back||Insert label||'..mm..'||'..mm2..'||Delete'
    else
      mstr = '#Move up|#Move down|#Bring to front|#Send to back||Insert label||#Copy formatting|#Paste formatting||#Lock position||#Delete'    
    end
    gfx.x, gfx.y = mouse.mx, mouse.my
    local mx, my = mouse.mx, mouse.my
    res = OpenMenu(mstr)
    if res ~= 0 then
      if res == 1 then
        if gfx2_select < #strips[tracks[track_select].strip][page].graphics then
          local tbl = {}
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select])
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select+1])
          strips[tracks[track_select].strip][page].graphics[gfx2_select] = tbl[2]
          strips[tracks[track_select].strip][page].graphics[gfx2_select+1] = tbl[1]
          gfx2_select = gfx2_select +1
        end
              
      elseif res == 2 then
        if gfx2_select > 1 then
          local tbl = {}
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select])
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select-1])
          strips[tracks[track_select].strip][page].graphics[gfx2_select] = tbl[2]
          strips[tracks[track_select].strip][page].graphics[gfx2_select-1] = tbl[1]
          gfx2_select = gfx2_select -1
        end      
      
      elseif res == 3 then
        --to front
        if gfx2_select then
          local cnt = #strips[tracks[track_select].strip][page].graphics          
          local tbl = {}
          local tbl2 = {}
          table.insert(tbl2, strips[tracks[track_select].strip][page].graphics[gfx2_select])
          strips[tracks[track_select].strip][page].graphics[gfx2_select] = nil
          
          for i = 1, cnt do
            if strips[tracks[track_select].strip][page].graphics[i] ~= nil then
              table.insert(tbl, strips[tracks[track_select].strip][page].graphics[i])
            end
          end
          table.insert(tbl,tbl2[1])
          strips[tracks[track_select].strip][page].graphics = tbl
          gfx2_select = #strips[tracks[track_select].strip][page].graphics
        end  
          
      elseif res == 4 then
        --to back
        if gfx2_select then
          local cnt = #strips[tracks[track_select].strip][page].graphics          
          local tbl = {}
          table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select])
          strips[tracks[track_select].strip][page].graphics[gfx2_select] = nil
          
          for i = 1, cnt do
            if strips[tracks[track_select].strip][page].graphics[i] ~= nil then
              table.insert(tbl, strips[tracks[track_select].strip][page].graphics[i])
            end
          end
          strips[tracks[track_select].strip][page].graphics = tbl
          gfx2_select = 1
        end  

      elseif res == 5 then
      
        InsertLabel(mx,my)

      elseif res == 6 then

        local tbl = {}     
        table.insert(tbl, strips[tracks[track_select].strip][page].graphics[gfx2_select])
        gfx_lblformat_copy = tbl[1]
      
      elseif res == 7 then
      
        if gfx_lblformat_copy then
        
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.name = gfx_lblformat_copy.font.name
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.size = gfx_lblformat_copy.font.size
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.bold = gfx_lblformat_copy.font.bold
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.italics = gfx_lblformat_copy.font.italics
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.underline = gfx_lblformat_copy.font.underline
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow = gfx_lblformat_copy.font.shadow
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_x = gfx_lblformat_copy.font.shadow_x
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_y = gfx_lblformat_copy.font.shadow_y
          strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_a = gfx_lblformat_copy.font.shadow_a
          strips[tracks[track_select].strip][page].graphics[gfx2_select].text_col = gfx_lblformat_copy.text_col
          
        end

      elseif res == 8 then

        strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock = not strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock
        poslock_select = strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock
        update_gfx = true
        
      elseif res == 9 then
        DeleteSelectedCtls()
        update_gfx = true
      end
    end
    update_gfx = true    
  end
  
  function InsertLabel(x,y)
  
    label_add = {x = x, y = y}
    EditLabel(6)
  
  end
  
  function InsertLabel2(txt)
  
    if txt and txt ~= '' then
    
      gfx_text_select = txt
      Strip_AddGFX(gfxtype.txt)
    
    end
    
  end
  
  function EditLabel(eb,txt)
  
    if strips and strips[tracks[track_select].strip] then
    
      if txt == nil then txt = "" end
      local sizex,sizey = 400,200
      editbox={title = 'Please enter text for label:',
        x=400, y=100, w=120, h=20, l=4, maxlen=40,
        fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
        txtcol=0x000000, curscol=0x000000,
        font=1, fontsz=14, caret=string.len(txt), sel=0, cursstate=0,
        text=txt, 
        hasfocus=true
      }
      
      EB_Open = eb
    end
    
  end
  
  function EditLabel2(txt)
  
    --for i = 1, #ctl_select do
    if string.len(txt) > 0 then
      gfx_text_select = txt
      strips[tracks[track_select].strip][page].graphics[gfx2_select].text = txt
    end
    --end
    
  end

  function EditFont()
  
    if strips and strips[tracks[track_select].strip] then
    
      local txt = gfx_font_select.name
      local sizex,sizey = 400,200
      editbox={title = 'Please enter font name:',
        x=400, y=100, w=120, h=20, l=4, maxlen=40,
        fgcol=0x000000, fgfcol=0x00FF00, bgcol=0x808080,
        txtcol=0x000000, curscol=0x000000,
        font=1, fontsz=14, caret=string.len(txt), sel=0, cursstate=0,
        text=txt, 
        hasfocus=true
      }
      
      EB_Open = 8
    end
    
  end

  function EditFont2(font)

    gfx.setfont(1,font)
    local f2,f3 = gfx.getfont()
    gfx_font_select.name = f3
    strips[tracks[track_select].strip][page].graphics[gfx2_select].font.name = f3

  end
    
  function TopMenu()
  
    local mstr
    local ds
    local ls = ''
    local d = gfx.dock(-1)
    if d%256 == 0 then
      ds = 'Dock Window'
    else
      ds = 'Undock Window'
    end
    if settings_locksurface then
      ls = '!'
    end
    local dt = ''
    if (strips and tracks[track_select].strip and strips[tracks[track_select].strip] and #strips[tracks[track_select].strip][page].controls > 0) or strip_default == nil then
      dt = '#'      
    end
    if mode == 0 then
      mstr = 'Toggle Sidebar||Lock X|Lock Y|Scroll Up|Scroll Down||Save Script State|Open Settings||Page 1|Page 2|Page 3|Page 4||'..ds..'||'..ls..'Lock Surface||'..dt..'Insert Default Strip'
    else
      mstr = '#Toggle Sidebar||Lock X|Lock Y|Scroll Up|Scroll Down||Save Script State|Open Settings||Page 1|Page 2|Page 3|Page 4||'..ds..'||'..ls..'Lock Surface||'..dt..'Insert Default Strip'
    end
    gfx.x, gfx.y = mouse.mx, butt_h
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
      elseif res == 12 then
        if d%256 == 0 then d=d+1 else d=d-1 end
        gfx.dock(d)
      elseif res == 13 then
        settings_locksurface = not settings_locksurface
      elseif res == 14 then
        stripfol_select = strip_default.stripfol_select
        strip_select = strip_default.strip_select
        loadstrip = LoadStrip(strip_select)
        GenStripPreview(gui, loadstrip.strip)
        Strip_AddStrip(loadstrip,0,0)
        loadstrip = nil
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
    if settings_locksurface == false then
      if surface_offset.y > 0 then
        if lockh > 0 then
          surface_offset.y = surface_offset.y - lockh
        else
          surface_offset.y = surface_offset.y - math.floor(obj.sections[10].h/settings_gridsize)*settings_gridsize
        end
      end
    end
  end
  
  function ScrollDown()
    if settings_locksurface == false then
      if surface_offset.y < surface_size.h-obj.sections[10].h then
        if lockh > 0 then
          surface_offset.y = surface_offset.y + lockh
        else
          surface_offset.y = surface_offset.y + math.floor(obj.sections[10].h/settings_gridsize)*settings_gridsize
        end
      end
    end
  end
  
  function SetPage(lpage)
    
    page = lpage
    ctl_select = nil
    gfx2_select = nil
    gfx3_select = nil
    ss_select = nil
    
    if strips and tracks[track_select] and strips[tracks[track_select].strip] then
      strips[tracks[track_select].strip].page = page
      surface_offset.x = tonumber(strips[tracks[track_select].strip][page].surface_x)
      surface_offset.y = tonumber(strips[tracks[track_select].strip][page].surface_y)
    else
      surface_offset.x = 0
      surface_offset.y = 0       
    end
    
    --if settings_autocentrectls then
    --  AutoCentreCtls()
    --end
    update_gfx = true
    
  end
  
  function SetCtlSelectVals()
    ctltype_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctltype
    knob_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].knob_select
    scale_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
    textcol_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textcol
    show_paramname = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramname
    show_paramval = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].show_paramval
    textoff_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textoff
    textoffval_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textoffval
    textsize_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].textsize
    defval_select = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].defval
    maxdp_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].maxdp,-1)                  
    dvaloff_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].dvaloffset,'')                  
    --knob_scalemode_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scalemode,1)                  
    scalemode_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scalemode,8)
    framemode_select = nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].framemode,1)
    SetKnobScaleMode()
    cycle_select = Cycle_CopySelectIn(ctl_select[1].ctl)
    local min, max = GetParamMinMax_ctl(ctl_select[1].ctl)
    minov_select = min
    maxov_select = max
  end

  function SetKnobScaleMode()
  
    if scalemode_select == 8 and framemode_select == 1 then
      knob_scalemode_select = 2
    elseif scalemode_select == 12 and framemode_select == 2 then
      knob_scalemode_select = 3
    else
      knob_scalemode_select = 1
    end
  
  end

  function SetGfxSelectVals()
    gfx_font_select.name = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.name
    gfx_font_select.size = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.size
    gfx_font_select.bold = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.bold
    gfx_font_select.italic = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.italic
    gfx_font_select.underline = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.underline
    gfx_font_select.shadow = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow
    gfx_font_select.shadow_x = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_x
    gfx_font_select.shadow_y = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_y
    gfx_font_select.shadow_a = strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_a
    gfx_textcol_select = strips[tracks[track_select].strip][page].graphics[gfx2_select].text_col
    gfx_text_select = strips[tracks[track_select].strip][page].graphics[gfx2_select].text
    poslock_select = strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock
  end
  
  function GetValFromDVal(c, dv)
  
    if c then
      local t = strips[tracks[track_select].strip].track.tracknum
      if strips[tracks[track_select].strip][page].controls[c].tracknum ~= nil then
        t = strips[tracks[track_select].strip][page].controls[c].tracknum
      end
      local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat
      if cc == ctlcats.fxparam or cc == ctlcats.trackparam or cc == ctlcats.tracksend then

        local f = strips[tracks[track_select].strip][page].controls[c].fxnum
        local p = strips[tracks[track_select].strip][page].controls[c].param
        track = GetTrack(t)
        
        --local v, min, max = reaper.TrackFX_GetParam(track, f, p)
        local v = GetParamValue_Ctl(c)
        local min, max = GetParamMinMax_ctl(c)
        
        --[[if strips[tracks[track_select].strip][page].controls[c].minov then
          min = strips[tracks[track_select].strip][page].controls[c].minov
        end
        if strips[tracks[track_select].strip][page].controls[c].maxov then
          max = strips[tracks[track_select].strip][page].controls[c].maxov
        end]]
        local dvoff = strips[tracks[track_select].strip][page].controls[c].dvaloffset
        trackfxparam_select = c
        SetParam3(min)
        for i = 1, 100 do i=i end
        miv = tonumber(GetParamDisp(cc,t,f,p,dvoff,c))
        --for i = 1, 10 do i=i end
        
        SetParam3(max)
        for i = 1, 100 do i=i end
        mav = tonumber(GetParamDisp(cc,t,f,p,dvoff,c))
        if (miv == nil or mav == nil) or (miv and mav and mav > miv) then
        
          local pinc = 0
          local found = false
          local mdp = 50
          local nval, dval, dval2, rval = 0, '', '', 0
          for j = 0, mdp do
            for i = 0, 9 do
              local inc = (1/(10^j))*i
              nval = rval + inc
              SetParam3(nval)
              dval2 = GetParamDisp(cc,t,f,p,dvoff,c)
              dval = GetNumericPart(dval2)
              if tonumber(dval) then
                if tonumber(dval) == tonumber(dv) then
                  found = true
                  rval = nval
                  break
                elseif tonumber(dval) < tonumber(dv) then
                  if i ==9 then
                    rval = rval + inc
                  else
                    pinc = inc
                  end
                elseif tonumber(dval) > tonumber(dv) then
                  rval = rval + pinc
                  break
                end
              else
                pinc = inc
                rval = rval + inc
              end        
            end
    
            if found then
              break
            end
          end
          SetParam()    
          return rval
        else
          OpenMsgBox(1, 'Currently unavailable for this parameter.', 1)
  --[[DBG('bw')
                  local pinc = 0
                  local found = false
                  local mdp = 50
                  local nval, dval, dval2, rval = 0, '', '', 0
                  for j = 0, mdp do
                    pinc = 0
                    for i = 0, 9 do
                      local inc = (1/(10^j))*i
                      nval = rval + inc
                      SetParam3(nval)
                      for x = 1,20 do x=x end
                      dval2 = GetParamDisp(t,f,p,dvoff)
                      dval = GetNumericPart(dval2)
                      DBG(nval..'  '..dval)        
                      if tonumber(dval) then
                        if tonumber(dval) == tonumber(dv) then
                          found = true
                          rval = nval
                          break
                        elseif tonumber(dval) > tonumber(dv) then
                          if i == 9 then
                            rval = rval + inc
                          else
                            pinc = inc
                          end
                        elseif tonumber(dval) < tonumber(dv) then
                          DBG('brk'..pinc)
                          rval = rval + pinc - inc
                          break
                        end
                      else
                        pinc = inc
                        rval = rval + inc
                      end
                    end
            
                    if found then
                      break
                    end
                  end
                  SetParam()    
                  DBG('1nd')
                  return rval
       ]]
          return 0
        end
      elseif cc == ctlcats.trackparam then

      end
    end
  
  end
  
  function SetPosLockCtl()
  
    if ctl_select and #ctl_select > 0 then
      poslockctl_select = true
      for i = 1, #ctl_select do
        if nz(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].poslock,false) == false then
          poslockctl_select = false
          break
        end    
      end
    else
      poslockctl_select = false
    end
      
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
      if not r or gfx.dock(-1) > 0 then 
        gfx1.main_w = gfx.w
        gfx1.main_h = gfx.h
        win_w = gfx.w
        win_h = gfx.h
  
        last_gfx_w = gfx.w
        last_gfx_h = gfx.h
        
        gui = GetGUI_vars()
        obj = GetObjects()
        
       -- if settings_autocentrectls then
       --   AutoCentreCtls()
       -- end
        
        resize_display = true
        update_gfx = true
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
      local st = reaper.GetSelectedTrack(0,0)
      if st == nil then
        track_select = -1
        --update_gfx = true
      end
      CheckStripSends()
      PopulateTrackSendsInfo()
    --[[else
      --check track
      checktr = checktr + 1
      if checktr > reaper.CountTracks(0)-1 then
        checktr = 0
      end
      local mt = reaper.GetTrack(0,checktr)
      if tracks[checktr].guid ~= reaper.GetTrackGUID(mt) 
         or tracks[checktr].tracknum ~= checktr then
      end
      ]]
    end    
    
    GUI_draw(obj, gui)
    
    local noscroll = false
    
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
                if tr ~= nil then
                  tracks[i].name = reaper.GetTrackState(tr)
                  if reaper.GetTrackGUID(st) == reaper.GetTrackGUID(tr) then
                    if strips[tracks[track_select].strip] then
                      strips[tracks[track_select].strip].page = page
                    end
                    track_select = i
                    trackedit_select = track_select
                    
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
              CheckStripSends()          
              PopulateTrackSendsInfo()
              PopulateTrackFX()
              ctl_select = nil
              gfx2_select = nil
              gfx3_select = nil
              ss_select = nil
              --if settings_autocentrectls then
              --  AutoCentreCtls()
              --end
              update_gfx = true
            end
          end 
        end
      end      
    end
    
    local checksends = false
    if settings_disablesendchecks == false and rt >= time_checksend then
      time_checksend = rt + 2
      checksends = true
    end
    
    if rt >= time_nextupdate then
      local suf = settings_updatefreq
      if mode == 1 then suf = 0.2 end

      time_nextupdate = rt + suf
      if strips and tracks[track_select] and strips[tracks[track_select].strip] and #strips[tracks[track_select].strip][page].controls > 0 then
        --check track
        if CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip) then
          local tr2 = GetTrack(strips[tracks[track_select].strip].track.tracknum)
          if tr2 ~= nil then
            if strips and strips[tracks[track_select].strip] then
              local chktbl = {}
              for i = 1, #strips[tracks[track_select].strip][page].controls do
                --check fx
                
                tr = tr2
                local tr_found = true
                if strips[tracks[track_select].strip][page].controls[i].tracknum ~= nil then
                  --tr = GetTrack(strips[tracks[track_select].strip][page].controls[i].tracknum)
                  tr_found = CheckTrack(strips[tracks[track_select].strip][page].controls[i].tracknum, tracks[track_select].strip, page, i)
                  if tr_found then
                    tr = GetTrack(strips[tracks[track_select].strip][page].controls[i].tracknum)
                  end 
                end
                
                if tr_found then
                  if strips[tracks[track_select].strip][page].controls[i].ctlcat == ctlcats.fxparam then
                    local fxguid = reaper.TrackFX_GetFXGUID(tr, strips[tracks[track_select].strip][page].controls[i].fxnum)
                    if strips[tracks[track_select].strip][page].controls[i].fxguid == fxguid then
                      local v = GetParamValue2(strips[tracks[track_select].strip][page].controls[i].ctlcat,
                                               tr,
                                               strips[tracks[track_select].strip][page].controls[i].fxnum,
                                               strips[tracks[track_select].strip][page].controls[i].param, i)
                      if strips[tracks[track_select].strip][page].controls[i].ctltype == 4 then
                        if tostring(strips[tracks[track_select].strip][page].controls[i].val) ~= tostring(v) then
                        --DBG(tostring(strips[tracks[track_select].strip][page].controls[i].val)..'  '..tostring(v))
                          strips[tracks[track_select].strip][page].controls[i].val = v
                          strips[tracks[track_select].strip][page].controls[i].dirty = true
                          if strips[tracks[track_select].strip][page].controls[i].param_info.paramname == 'Bypass' then
                            SetCtlEnabled(strips[tracks[track_select].strip][page].controls[i].fxnum) 
                          end
                          strips[tracks[track_select].strip][page].controls[i].cycledata.posdirty = true 
                          update_ctls = true
                        end
                      else
                        if strips[tracks[track_select].strip][page].controls[i].val ~= v then
                          strips[tracks[track_select].strip][page].controls[i].val = v
                          strips[tracks[track_select].strip][page].controls[i].dirty = true
                          if strips[tracks[track_select].strip][page].controls[i].param_info.paramname == 'Bypass' then
                            SetCtlEnabled(strips[tracks[track_select].strip][page].controls[i].fxnum) 
                          end
                          update_ctls = true
                        end                      
                      end
                    else
                      if strips[tracks[track_select].strip][page].controls[i].fxfound then
                        CheckStripControls()
                      end
                    end
                  elseif strips[tracks[track_select].strip][page].controls[i].ctlcat == ctlcats.trackparam then
                    local v = GetParamValue2(strips[tracks[track_select].strip][page].controls[i].ctlcat,
                                             tr,
                                             nil,
                                             strips[tracks[track_select].strip][page].controls[i].param, i)
                    if strips[tracks[track_select].strip][page].controls[i].ctltype == 4 then
                      if tostring(strips[tracks[track_select].strip][page].controls[i].val) ~= tostring(v) then
                        strips[tracks[track_select].strip][page].controls[i].val = v
                        strips[tracks[track_select].strip][page].controls[i].dirty = true
                        strips[tracks[track_select].strip][page].controls[i].cycledata.posdirty = true 
                        update_ctls = true
                      end
                    else
                      if strips[tracks[track_select].strip][page].controls[i].val ~= v then
                        strips[tracks[track_select].strip][page].controls[i].val = v
                        strips[tracks[track_select].strip][page].controls[i].dirty = true
                        update_ctls = true
                      end
                    end                    
                  elseif strips[tracks[track_select].strip][page].controls[i].ctlcat == ctlcats.tracksend then

                    if settings_disablesendchecks == false and checksends == true then
                      local tt = strips[tracks[track_select].strip][page].controls[i].tracknum
                      if tt == nil then
                        tt = strips[tracks[track_select].strip].track.tracknum
                      end
                      local chk
                      
                      chk, chktbl[tt] = CheckSendGUID(tt,nil,strips[tracks[track_select].strip][page].controls[i].param_info.paramnum,
                                                            strips[tracks[track_select].strip][page].controls[i].param_info.paramdestguid,
                                                            strips[tracks[track_select].strip][page].controls[i].param_info.paramdestchan,
                                                            strips[tracks[track_select].strip][page].controls[i].param_info.paramsrcchan,
                                                            chktbl[tt])
                      if chk == false then
                        chktbl = CheckStripSends(chktbl)
                      end
                    end                    

                    local v = GetParamValue2(strips[tracks[track_select].strip][page].controls[i].ctlcat,
                                             tr,
                                             nil,
                                             strips[tracks[track_select].strip][page].controls[i].param, i)

                    if strips[tracks[track_select].strip][page].controls[i].ctltype == 4 then
                      if tostring(strips[tracks[track_select].strip][page].controls[i].val) ~= tostring(v) then
                        strips[tracks[track_select].strip][page].controls[i].val = v
                        strips[tracks[track_select].strip][page].controls[i].dirty = true
                        strips[tracks[track_select].strip][page].controls[i].cycledata.posdirty = true 
                        update_ctls = true                    
                      end
                    else
                      if strips[tracks[track_select].strip][page].controls[i].val ~= v then
                        strips[tracks[track_select].strip][page].controls[i].val = v
                        strips[tracks[track_select].strip][page].controls[i].dirty = true
                        update_ctls = true
                      end
                    end
                  end
                end
              end
              chktbl = nil
            end
          end
        end
      end
    end
    
    if show_settings then
      if mouse.LB and not mouse.last_LB and not MOUSE_click(obj.sections[70]) then
        show_settings = false
        SaveSettings()
        update_gfx = true      
      end
      
      if MOUSE_click(obj.sections[71]) then
        settings_followselectedtrack = not settings_followselectedtrack
        update_settings = true
      elseif MOUSE_click(obj.sections[72]) then
        settings_disablesendchecks = not settings_disablesendchecks
        update_settings = true
      elseif MOUSE_click(obj.sections[73]) then
        settings_saveallfxinststrip = not settings_saveallfxinststrip
        update_settings = true
      elseif MOUSE_click(obj.sections[81]) then
        settings_mousewheelknob = not settings_mousewheelknob
        update_settings = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[74]) then
        mouse.context = contexts.updatefreq
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
        mouse.context = contexts.lockw
        ctlpos = lockw
      elseif mouse.context == nil and MOUSE_click(obj.sections[78]) then
        mouse.context = contexts.lockh
        ctlpos = lockh
      elseif mouse.context == nil and MOUSE_click(obj.sections[80]) then
        settings_showgrid = not settings_showgrid
        osg = settings_showgrid
        if settings_gridsize < 16 then
          settings_showgrid = false
        end
        update_gfx = true
      elseif mouse.context == nil and MOUSE_click(obj.sections[79]) then
        mouse.context = contexts.gridslider
        ctlpos = settings_gridsize
      end
      
      if mouse.context and mouse.context == contexts.updatefreq then
        local val = F_limit(MOUSE_sliderHBar(obj.sections[74]),0,1)
        if val ~= nil then
          settings_updatefreq = (1-val)/10
          if oval ~= settings_updatefreq then
            update_settings = true                  
          end 
          oval = settings_updatefreq          
        end
      elseif mouse.context and mouse.context == contexts.lockw then
        local val = F_limit(MOUSE_slider(obj.sections[77]),0,1)
        if val ~= nil then
          val = 1-val
          lockw = F_limit( math.floor((val*1000)/settings_gridsize)*settings_gridsize,64,1000)
          obj = GetObjects()
          update_gfx = true
        end
      elseif mouse.context and mouse.context == contexts.lockh then
        local val = F_limit(MOUSE_slider(obj.sections[78]),0,1)
        if val ~= nil then
          val = 1-val
          lockh = F_limit( math.floor((val*1000)/settings_gridsize)*settings_gridsize,64,1000)
          obj = GetObjects()
          update_gfx = true
        end
      elseif mouse.context and mouse.context == contexts.gridslider then
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
    
      local c=gfx.getchar()  
      mb_onchar(c)
      
      if MOUSE_click(obj.sections[62]) or MB_Enter then
        --OK
        if MS_Open == 1 then
          msgbox = nil
        end
        MS_Open = 0
        MB_Enter = false 
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
      
      if MOUSE_click(obj.sections[6]) or EB_Enter then
        --OK
        EB_Enter = false
        if EB_Open == 1 then
          SaveStrip2(editbox.text)
        elseif EB_Open == 2 then
          EditCtlName2(editbox.text)
        elseif EB_Open == 3 then
          EditDValOffset2(editbox.text)
          update_gfx = true
        elseif EB_Open == 4 then
          EditMinDVal2(editbox.text)
          update_gfx = true
        elseif EB_Open == 5 then
          EditValue2(editbox.text)
          --update_ctls = true
        elseif EB_Open == 6 then
          InsertLabel2(editbox.text)
        elseif EB_Open == 7 then
          EditLabel2(editbox.text)
        elseif EB_Open == 8 then
          EditFont2(editbox.text)
        elseif EB_Open == 10 then
          EditCycleDV(editbox.text)        
        elseif EB_Open == 11 then
          EditSSName2(editbox.text)
          update_snaps = true
        end
        editbox = nil
        EB_Open = 0
      
      elseif MOUSE_click(obj.sections[7]) then
        editbox = nil
        EB_Open = 0
      end
          
      local c=gfx.getchar()  
      if editbox and editbox.hasfocus then editbox_onchar(editbox, c) end  
      update_gfx = true
    else
    
    if MOUSE_click(obj.sections[21]) then
    
      TopMenu()

    elseif MOUSE_click(obj.sections[14]) then
      --page
      local page = F_limit(math.ceil((mouse.mx-obj.sections[14].x)/(obj.sections[14].w/4)),1,4)
      SetPage(page)            
    
    elseif MOUSE_click(obj.sections[11]) then
      if mouse.mx > obj.sections[11].w-6 then
        mouse.context = contexts.dragsidebar
        offx = 0
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
        mouse.context = contexts.dragsidebar
        offx = mouse.mx-plist_w
      end
    
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
    
    if mouse.context and mouse.context == contexts.dragsidebar then
    
      plist_w = math.max(mouse.mx-offx,0)
      plist_w = math.min(plist_w, obj.sections[19].x-2)
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

        if MOUSE_over(obj.sections[160]) then
          if snapshots and snapshots[tracks[track_select].strip] and
             snapshots[tracks[track_select].strip][page][sstype_select] then
            ssoffset = F_limit(ssoffset - v, 0, #snapshots[tracks[track_select].strip][page][sstype_select]-1)
            update_snaps = true
          end     
          gfx.mouse_wheel = 0
        end
      end
      
      if mouse.context == nil and show_snapshots == true and (MOUSE_click(obj.sections[160]) or MOUSE_click_RB(obj.sections[160])) then
      
        xywh = {x = obj.sections[160].x,
                y = obj.sections[160].y,
                w = obj.sections[160].w,
                h = butt_h}
        if MOUSE_click(xywh) then 
          mouse.context = contexts.movesnapwindow
          movesnapwin = {offx = mouse.mx - obj.sections[160].x,
                         offy = mouse.my - obj.sections[160].y}
        end
        
        local snapmx, snapmy = mouse.mx, mouse.my
        mouse.mx = mouse.mx - obj.sections[160].x
        mouse.my = mouse.my - obj.sections[160].y
        
        if mouse.context == nil and MOUSE_click(obj.sections[165]) then
          mouse.context = contexts.resizesnapwindow
          resizesnapwin = {origh = obj.sections[160].h,
                           offy = mouse.my}          
        end        
        
        if mouse.context == nil and MOUSE_click(obj.sections[162]) then
        
          Snapshots_CREATE(tracks[track_select].strip, page, sstype_select)
          update_snaps = true
        end
      
        if MOUSE_click(obj.sections[163]) then
          if snapshots and snapshots[tracks[track_select].strip] then
            local i = math.floor((mouse.my-obj.sections[163].y)/butt_h)
        
            if i == 0 then
              local ix = math.floor((mouse.mx-obj.sections[163].x)/(obj.sections[160].w/2))
              if ix == 0 then
                ssoffset = ssoffset-1
                if ssoffset < 0 then ssoffset = 0 end
              else
                ssoffset = F_limit(ssoffset+1,0,math.max(0,#snapshots[tracks[track_select].strip][page][sstype_select]-SS_butt_cnt))
              end
              update_snaps = true
            else
              if snapshots and snapshots[tracks[track_select].strip] then
                ss_select = F_limit(ssoffset+i,1,#snapshots[tracks[track_select].strip][page][sstype_select])
                --if mouse.lastLBclicktime and (rt-mouse.lastLBclicktime) < 0.20 then
                
                  Snapshot_Set(tracks[track_select].strip, page)
                
                --end
                update_snaps = true          
              end
            end
          end
        elseif MOUSE_click_RB(obj.sections[163]) then
          if ss_select then
            mstr = 'Rename||Delete||Capture (Overwrite)'
            gfx.x, gfx.y = snapmx, snapmy
            res = OpenMenu(mstr)
            if res ~= 0 then
              if res == 1 then
                EditSSName(11)
              elseif res == 2 then
                DeleteSS()
                update_snaps = true
              elseif res == 3 then
                Snapshots_CREATE(tracks[track_select].strip, page, sstype_select, ss_select)
              end
            end
          end        
        end
        
        mouse.mx = snapmx
        mouse.my = snapmy
        noscroll = true
      elseif mouse.context == nil and (MOUSE_click(obj.sections[10]) or MOUSE_click_RB(obj.sections[10]) or gfx.mouse_wheel ~= 0) then
        if mouse.mx > obj.sections[10].x then
          if strips and tracks[track_select] and strips[tracks[track_select].strip] then
            for i = 1, #strips[tracks[track_select].strip][page].controls do

              ctlxywh = {x = strips[tracks[track_select].strip][page].controls[i].xsc - surface_offset.x +obj.sections[10].x, 
                         y = strips[tracks[track_select].strip][page].controls[i].ysc - surface_offset.y +obj.sections[10].y, 
                         w = strips[tracks[track_select].strip][page].controls[i].wsc, 
                         h = strips[tracks[track_select].strip][page].controls[i].hsc}
                         
              --if strips[tracks[track_select].strip][page].controls[i].ctlcat == ctlcats.fxparam then
              
              if strips[tracks[track_select].strip][page].controls[i].fxfound then
                if MOUSE_click(ctlxywh) and not mouse.ctrl then
                  local ctltype = strips[tracks[track_select].strip][page].controls[i].ctltype
                
                  if mouse.lastLBclicktime and (rt-mouse.lastLBclicktime) < 0.15 then
                    --double-click
                    if ctltype == 1 then
                      trackfxparam_select = i
                      EditValue(5)
                      break
                    end
                  end
                
                  if ctltype == 1 then
                    --knob/slider
                    mouse.context = contexts.sliderctl
                    --knobslider = 'ks'
                    ctlpos = ctlScaleInv(nz(strips[tracks[track_select].strip][page].controls[i].scalemode,8),
                                         strips[tracks[track_select].strip][page].controls[i].val)
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
                    noscroll = true
                    update_ctls = true
                  elseif ctltype == 4 then
                    --cycle
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.pos == nil then
                      strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 1
                    else
                      strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 
                                  strips[tracks[track_select].strip][page].controls[i].cycledata.pos +1
                      if strips[tracks[track_select].strip][page].controls[i].cycledata.pos > 
                              strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt 
                         or strips[tracks[track_select].strip][page].controls[i].cycledata.pos < 1 then
                        strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 1
                      end
                    end
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.pos <=     
                              strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt then
                      trackfxparam_select = i
                      strips[tracks[track_select].strip][page].controls[i].val = 
                          strips[tracks[track_select].strip][page].controls[i].cycledata[strips[tracks[track_select].strip][page].controls[i].cycledata.pos].val
                      SetParam()
                      strips[tracks[track_select].strip][page].controls[i].dirty = true
                      strips[tracks[track_select].strip][page].controls[i].cycledata.posdirty = false
                      update_ctls = true
                    end
                    noscroll = true
                  elseif ctltype == 6 then
                    --mem button
                    trackfxparam_select = i
                    if strips[tracks[track_select].strip][page].controls[i].membtn.state == nil then
                      strips[tracks[track_select].strip][page].controls[i].membtn.state = false
                    end
                    strips[tracks[track_select].strip][page].controls[i].membtn.state = not strips[tracks[track_select].strip][page].controls[i].membtn.state
                    if strips[tracks[track_select].strip][page].controls[i].membtn.state == true then
                      strips[tracks[track_select].strip][page].controls[i].membtn.mem = strips[tracks[track_select].strip][page].controls[i].val
                      strips[tracks[track_select].strip][page].controls[i].val = strips[tracks[track_select].strip][page].controls[i].defval
                      SetParam()
                    else
                      strips[tracks[track_select].strip][page].controls[i].val = strips[tracks[track_select].strip][page].controls[i].membtn.mem
                      SetParam()
                    end
                    update_ctls = true                    
                  end
                  break
                  
                elseif MOUSE_click_RB(ctlxywh) and mouse.ctrl == false then
                  local mstr
                  mm = ''
                  if show_snapshots then
                    mm = '!'
                  end
                  if strips[tracks[track_select].strip][page].controls[i].ctlcat == ctlcats.fxparam then
                    mstr = 'MIDI learn|Modulation||Enter value||Open FX window||'..mm..'Snapshots'
                  else
                    mstr = '#MIDI learn|#Modulation||Enter value||#Open FX window||'..mm..'Snapshots'                  
                  end
                  trackfxparam_select = i
                  gfx.x, gfx.y = mouse.mx, mouse.my
                  res = OpenMenu(mstr)
                  if res ~= 0 then
                    if res == 1 then
                      SetParam2(true)
                      reaper.Main_OnCommand(41144,0)
                    elseif res == 2 then
                      SetParam2(true)
                      reaper.Main_OnCommand(41143,0)
                    elseif res == 3 then
                      EditValue(5)
                    
                    elseif res == 4 then
                      local track
                      if strips[tracks[track_select].strip][page].controls[i].tracknum == nil then
                        track = GetTrack(tracks[track_select].tracknum)
                      else
                        track = GetTrack(strips[tracks[track_select].strip][page].controls[i].tracknum)                      
                      end
                      local fxnum = strips[tracks[track_select].strip][page].controls[i].fxnum
                      if not reaper.TrackFX_GetOpen(track, fxnum) then
                        reaper.TrackFX_Show(track, fxnum, 3)
                      end
                    elseif res == 5 then
                      show_snapshots = not show_snapshots
                      update_gfx = true
                    end
                  end
                  noscroll = true
                  break
                --elseif MOUSE_click_RB(ctlxywh) and mouse.ctrl then
                
                --  trackfxparam_select = i
                --  EditValue()
                
                elseif MOUSE_click(ctlxywh) and mouse.ctrl then --make double_click?
                  --default val
                  trackfxparam_select = i
                  local ctltype = strips[tracks[track_select].strip][page].controls[i].ctltype
                  if ctltype == 1 then                  
                    strips[tracks[track_select].strip][page].controls[i].val = strips[tracks[track_select].strip][page].controls[i].defval
                    SetParam()
                    strips[tracks[track_select].strip][page].controls[i].dirty = true
                    update_ctls = true
                  elseif ctltype == 4 then                  
                    strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 1
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.pos <=     
                              strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt then
                      trackfxparam_select = i
                      strips[tracks[track_select].strip][page].controls[i].val = 
                          strips[tracks[track_select].strip][page].controls[i].cycledata[strips[tracks[track_select].strip][page].controls[i].cycledata.pos].val
                      SetParam()
                      strips[tracks[track_select].strip][page].controls[i].dirty = true
                    end                  
                    update_ctls = true
                  elseif ctltype == 6 then
                    strips[tracks[track_select].strip][page].controls[i].defval = GetParamValue_Ctl(i)                                    
                  end

                  noscroll = true
                  break
                
                elseif settings_mousewheelknob and gfx.mouse_wheel ~= 0 and MOUSE_over(ctlxywh) then
                  local ctltype = strips[tracks[track_select].strip][page].controls[i].ctltype
                  if ctltype == 1 then
                    trackfxparam_select = i
                    local v = gfx.mouse_wheel/120 * 0.003
                    strips[tracks[track_select].strip][page].controls[i].val = F_limit(strips[tracks[track_select].strip][page].controls[i].val+v,0,1)
                    SetParam()
                    update_ctls = true
                    gfx.mouse_wheel = 0
                  elseif ctltype == 4 then
                    local v = gfx.mouse_wheel/120
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.pos == nil then
                      strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 1
                    else
                      strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 
                                  strips[tracks[track_select].strip][page].controls[i].cycledata.pos + v
                      if strips[tracks[track_select].strip][page].controls[i].cycledata.pos < 1 then
                        strips[tracks[track_select].strip][page].controls[i].cycledata.pos = strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt
                      elseif strips[tracks[track_select].strip][page].controls[i].cycledata.pos > 
                              strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt then
                        strips[tracks[track_select].strip][page].controls[i].cycledata.pos = 1
                      end
                    end
                    if strips[tracks[track_select].strip][page].controls[i].cycledata.pos <=     
                              strips[tracks[track_select].strip][page].controls[i].cycledata.statecnt then
                      trackfxparam_select = i
                      strips[tracks[track_select].strip][page].controls[i].val = 
                          strips[tracks[track_select].strip][page].controls[i].cycledata[strips[tracks[track_select].strip][page].controls[i].cycledata.pos].val
                      SetParam()
                      strips[tracks[track_select].strip][page].controls[i].dirty = true
                      update_ctls = true
                    end
                    noscroll = true
                    gfx.mouse_wheel = 0                  
                  end
                  break
                end

              end
            end
            --DBG(noscroll)
            if noscroll == false and MOUSE_click_RB(obj.sections[10]) then
              mm = ''
              if show_snapshots then
                mm = '!'
              end
              mstr = '#MIDI learn|#Modulation||#Enter value||#Open FX window||'..mm..'Snapshots'
              gfx.x, gfx.y = mouse.mx, mouse.my
              res = OpenMenu(mstr)
              if res ~= 0 then
                if res == 5 then
                  show_snapshots = not show_snapshots
                  update_gfx = true
                end
              end
            end
          end
        end
      end

      if mouse.context and mouse.context == contexts.sliderctl then
        local val = MOUSE_slider(ctlxywh,mouse.slideoff)
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
            val = ctlScale(strips[tracks[track_select].strip][page].controls[trackfxparam_select].scalemode, val)
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
          if mouse.mx < obj.sections[43].w/2 then
            tlist_offset = tlist_offset - T_butt_cnt
            if tlist_offset < 0 then
              tlist_offset = 0
            end
          else
            if tlist_offset + T_butt_cnt < #tracks then
              tlist_offset = tlist_offset + T_butt_cnt
            end
          end
          update_gfx = true
        elseif tracks[i-1 + tlist_offset] then
          if tracks[track_select] and strips[tracks[track_select].strip] then
            strips[tracks[track_select].strip].page = page
          end
          track_select = i-1 + tlist_offset
          trackedit_select = track_select
          ss_select = nil
          
          if settings_followselectedtrack then
            --Select track
            local tr = GetTrack(track_select)
            tracks[track_select].name = reaper.GetTrackState(tr)
            
            if tr ~= nil then
              reaper.SetOnlyTrackSelected(tr)
            end
          
          end

          CheckStripSends()
          PopulateTrackSendsInfo()

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
          --if settings_autocentrectls then
          --  AutoCentreCtls()
          --end                
          update_gfx = true 
        end
      end
    
      if mouse.context and mouse.context == contexts.movesnapwindow then
        
        obj.sections[160].x = F_limit(mouse.mx - movesnapwin.offx, obj.sections[10].x, obj.sections[10].x+obj.sections[10].w-obj.sections[160].w)
        obj.sections[160].y = F_limit(mouse.my - movesnapwin.offy, obj.sections[10].y, obj.sections[10].y+obj.sections[10].h-obj.sections[160].h)
        
        update_msnaps = true
      
      end

      if mouse.context and mouse.context == contexts.resizesnapwindow then

        local ly = obj.sections[10].h - obj.sections[160].y + butt_h
        obj.sections[160].h = F_limit(resizesnapwin.origh + (mouse.my - resizesnapwin.offy) - obj.sections[160].y, 180, ly)
        obj.sections[163].h = obj.sections[160].h - 116
        obj.sections[165].y = obj.sections[160].h - 6
        snaph = obj.sections[160].h
        update_msnaps = true
        resize_snaps = true
        --update_gfx = true
      end
            
    elseif mode == 1 then
      
      if ct == 0 then
        track_select = -1
        update_gfx = true
      end
    
      local tr = GetTrack(trackedit_select)
      if tr then
        local fxc = reaper.TrackFX_GetCount(tr)
        if fxc ~= ofxcnt then
          PopulateTrackFX()
          update_gfx = true
        end
      end
    
      if mouse.shift then
        settings_gridsize = 1
      else
        settings_gridsize = ogrid      
      end

      if strips and tracks[track_select] and strips[tracks[track_select].strip] and #strips[tracks[track_select].strip][page].controls > 0 then
        CheckTrack(strips[tracks[track_select].strip].track, tracks[track_select].strip)
      end
            
      if submode == 0 then
        
        if mouse.context == nil and fxmode == 1 and trctltype_select == 1 and rt > time_sendupdate then
          time_sendupdate = rt + 1
          PopulateTrackSendsInfo()
          update_gfx = true
        end
        
        if gfx.mouse_wheel ~= 0 then
          local v = gfx.mouse_wheel/120
          if MOUSE_over(obj.sections[41]) then
            if fxmode == 0 then
              flist_offset = F_limit(flist_offset - v, 0, #trackfx)
              update_gfx = true
              gfx.mouse_wheel = 0
            elseif fxmode == 1 then
              trctltypelist_offset = F_limit(trctltypelist_offset - v, 0, #trctltype_table-1)
              update_gfx = true
              gfx.mouse_wheel = 0            
            end
          end
          if MOUSE_over(obj.sections[42]) then
            if fxmode == 0 then
              plist_offset = F_limit(plist_offset - v, 0, #trackfxparams)
              update_gfx = true
              gfx.mouse_wheel = 0
            elseif fxmode == 1 then
              if trctltype_select == 0 then
                trctlslist_offset = F_limit(trctlslist_offset - v, 0, #trctls_table-1)
                update_gfx = true
                gfx.mouse_wheel = 0
              elseif trctltype_select == 1 then
                trctlslist_offset = F_limit(trctlslist_offset - v, 0, #trsends_table*3+2)
                update_gfx = true
                gfx.mouse_wheel = 0              
              end
            end          
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
            
            if MOUSE_over(obj.sections[55]) then
              ctltype_select = F_limit(ctltype_select + v,1,#ctltype_table)
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctltype = ctltype_select
              end
              show_cycleoptions = false
              update_gfx = true
              gfx.mouse_wheel = 0
            end
                        
          end
        end
        
        if show_paramlearn then
          last_touch_fx = GetLastTouchedFX(last_touch_fx)        
        end
        
        if show_paramlearn and (MOUSE_click(obj.sections[115]) or MOUSE_click_RB(obj.sections[115])) then
        
          --LEARN
          
          if MOUSE_click(obj.sections[115]) then
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
            mouse.context = contexts.dragparamlrn
          elseif MOUSE_click_RB(obj.sections[115]) then
            show_paramlearn = false
            ctl_select = nil
            update_gfx = true
          end          
        
        end
          
        if ctl_select ~= nil and (MOUSE_click(obj.sections[45]) or MOUSE_click_RB(obj.sections[45])) then
          
          --CONTROL OPTIONS
          
          if mouse.LB and mouse.my > obj.sections[45].y and mouse.my < obj.sections[45].y+butt_h then
            
            show_cycleoptions = false
            ctl_page = ctl_page + 1
            if ctl_page > 1 then
              ctl_page = 0
            end
            update_gfx = true
          end
          
          if ctl_page == 0 then
            if mouse.LB and mouse.my > obj.sections[45].y+butt_h and mouse.my < obj.sections[45].y+150 then
            
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
            elseif MOUSE_click_RB(obj.sections[55]) then
              ctltype_select = ctltype_select - 1
              if ctltype_select < 1 then ctltype_select = #ctltype_table end
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctltype = ctltype_select
              end
              update_gfx = true
            end
  
            if ctltype_select == 4 and MOUSE_click(obj.sections[67]) then
              show_cycleoptions = not show_cycleoptions
              if show_cycleoptions then
                cycle_select.val = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].val
              end
              update_gfx = true
            else
              show_cycleoptions = false          
            end
            
            if MOUSE_click(obj.sections[59]) then
              if ctl_select and #ctl_select > 0 then
                EditCtlName()
                update_gfx = true
              end
            end
            
            if MOUSE_click_RB(obj.sections[57]) then
              defval_select = GetParamValue_Ctl(ctl_select[1].ctl)
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval = GetParamValue_Ctl(ctl_select[i].ctl)
              end
              update_gfx = true
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
            
            if mouse.context == nil and MOUSE_click(obj.sections[50]) then mouse.context = contexts.scaleslider 
            elseif mouse.context == nil and MOUSE_click(obj.sections[56]) then mouse.context = contexts.offsetslider
            elseif mouse.context == nil and MOUSE_click(obj.sections[65]) then mouse.context = contexts.valoffsetslider 
            elseif mouse.context == nil and MOUSE_click(obj.sections[57]) then omx = -1 ctlpos = defval_select mouse.context = contexts.defvalslider
            elseif mouse.context == nil and MOUSE_click(obj.sections[58]) then mouse.context = contexts.textsizeslider end
    
          elseif ctl_page == 1 then
            
            if MOUSE_click(obj.sections[126]) then
            
              --EditMinDVal()
            
            end
            
            if MOUSE_click(obj.sections[125]) then
              EditDValOffset()
            end

            if MOUSE_click(obj.sections[131]) then
              knob_scalemode_select = knob_scalemode_select + 1
              if knob_scalemode_select > #scalemode_preset_table then knob_scalemode_select = 2 end
              if knob_scalemode_select == 2 then
                scalemode_select = 8
                framemode_select = 1
              elseif knob_scalemode_select == 3 then
                scalemode_select = 12
                framemode_select = 2              
              end
              
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scalemode = scalemode_select
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].framemode = framemode_select                
              end
              update_gfx = true                        
            end

            if MOUSE_click(obj.sections[132]) then
              scalemode_select = scalemode_select + 1
              if scalemode_select > #scalemode_table then scalemode_select = 1 end
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scalemode = scalemode_select
              end
              SetKnobScaleMode()
              update_gfx = true                                      
            elseif MOUSE_click_RB(obj.sections[132]) then
              scalemode_select = scalemode_select - 1
              if scalemode_select < 1 then scalemode_select = #scalemode_table end
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scalemode = scalemode_select
              end
              SetKnobScaleMode()
              update_gfx = true                                      
            end
          
            if MOUSE_click(obj.sections[133]) then
              framemode_select = framemode_select + 1
              if framemode_select > #framemode_table then framemode_select = 1 end
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].framemode = framemode_select
              end
              SetKnobScaleMode()
              update_gfx = true                                      
            elseif MOUSE_click_RB(obj.sections[133]) then
              framemode_select = framemode_select - 1
              if framemode_select < 1 then framemode_select = #framemode_table end
              for i = 1, #ctl_select do
                strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].framemode = framemode_select
              end
              SetKnobScaleMode()
              update_gfx = true                                      
            end
          
            if mouse.context == nil and MOUSE_click(obj.sections[128]) then
              mouse.context = contexts.minov
              trackfxparam_select = ctl_select[1].ctl
              ctlpos = minov_select
              mouse.slideoff = obj.sections[128].y+obj.sections[128].h/2 - mouse.my
              oms = mouse.shift
              for i = 1, #ctl_select do
                local min, max = GetParamMinMax_ctl(ctl_select[i].ctl)
                ctl_select[i].denorm_defval = DenormalizeValue(min,
                                                               max,
                                                               strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval)
              end
              minov_act = 'minov'
              
            elseif mouse.context == nil and MOUSE_click(obj.sections[129]) then 
              mouse.context = contexts.maxov 
              trackfxparam_select = ctl_select[1].ctl
              ctlpos = maxov_select
              mouse.slideoff = obj.sections[129].y+obj.sections[129].h/2 - mouse.my
              oms = mouse.shift
              for i = 1, #ctl_select do
                local min, max = GetParamMinMax_ctl(ctl_select[i].ctl)
                ctl_select[i].denorm_defval = DenormalizeValue(min,
                                                               max,
                                                               strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval)
              end
              maxov_act = 'maxov'

            end
          
          end
        
        elseif ctl_select ~= nil and show_cycleoptions and gfx.mouse_wheel ~= 0 and MOUSE_over(obj.sections[103]) then
        
          local v = gfx.mouse_wheel/120
          cyclist_offset = F_limit(cyclist_offset - v, 0, max_cycle-8)
          update_gfx = true
          gfx.mouse_wheel = 0
        
        elseif ctl_select ~= nil and show_cycleoptions and (MOUSE_click(obj.sections[100]) or MOUSE_click_RB(obj.sections[100])) then
        
          -- CYCLE OPTS
        
          if MOUSE_click(obj.sections[102]) then
            cyclist_offset = 0
            cycle_select.statecnt = F_limit(cycle_select.statecnt+1,0,max_cycle)
            Cycle_InitData()
            update_gfx = true
          elseif MOUSE_click_RB(obj.sections[102]) then
            cyclist_offset = 0
            cycle_select.statecnt = F_limit(cycle_select.statecnt-1,0,max_cycle)
            Cycle_InitData()
            update_gfx = true
          end
          
          if mouse.context == nil and MOUSE_click(obj.sections[101]) then 
            mouse.context = contexts.cycleknob
            cycle_editmode = true 
            trackfxparam_select = ctl_select[1].ctl
            ctlpos = cycle_select.val
            mouse.slideoff = obj.sections[101].y+obj.sections[101].h/2 - mouse.my
            oms = mouse.shift
          end
          
          if MOUSE_click(obj.sections[103]) then
            local i = math.floor((mouse.my - obj.sections[103].y) / butt_h)+1
            cycle_select.selected = F_limit(i+cyclist_offset,1,cycle_select.statecnt)
            --strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].cycledata.pos = cycle_select.selected
            update_gfx = true
          elseif MOUSE_click_RB(obj.sections[103]) then
            if cycle_select and cycle_select.selected then
              local mstr = 'Rename'
              gfx.x, gfx.y = mouse.mx, mouse.my
              local res = OpenMenu(mstr)
              if res == 1 then
                txt = EditValue(10)
              end
            end            
          end          

          if MOUSE_click(obj.sections[104]) then
            Cycle_Auto()
            cyclist_offset = 0
            update_gfx = true            
          end
        
          if MOUSE_click(obj.sections[105]) then
            local i = math.floor((mouse.mx-obj.sections[105].x)/(obj.sections[105].w/2))
            if #cycle_select < 8 then
              cyclist_offset = 0
            else
              if i >= 1 then
                cyclist_offset = F_limit(cyclist_offset+1,0,math.max(#cycle_select-8,0))
              else
                cyclist_offset = F_limit(cyclist_offset-1,0,math.max(#cycle_select-8,0))            
              end
            end
            update_gfx = true            
          end
          
          if MOUSE_click(obj.sections[106]) then
            trackfxparam_select = ctl_select[1].ctl
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata = Cycle_CopySelectOut()
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].cycledata.pos = cycle_select.selected
            strips[tracks[track_select].strip][page].controls[trackfxparam_select].dirty = true
            show_cycleoptions = false
            cycle_editmode = false
            update_gfx = true
          end

          if MOUSE_click(obj.sections[107]) then
            cycle_select.mapptof = not cycle_select.mapptof
            update_gfx = true
          end          
        
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
                
                  mouse.context = contexts.dragctl
                  dragctl = 'dragctl'
                  show_cycleoptions = false
                  
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
                  
                  SetCtlSelectVals()
                  SetPosLockCtl()
                                                       
                  dragoff = {x = mouse.mx - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w - surface_offset.x,
                             y = mouse.my - strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh - surface_offset.y}
                             
                  update_gfx = true
                  break
                end
              end
            end
          elseif mouse.context == nil and MOUSE_click_RB(obj.sections[10]) then
            mouse.context = contexts.draglasso
            lasso = {l = mouse.mx, t = mouse.my, r = mouse.mx+5, b = mouse.my+5}
          end
        end
        
        if mouse.context and mouse.context == contexts.minov then
          local val = MOUSE_slider(obj.sections[128],mouse.slideoff)
          if val ~= nil then
            if oms ~= mouse.shift then
              oms = mouse.shift
              ctlpos = minov_select
              mouse.slideoff = obj.sections[128].y+obj.sections[128].h/2 - mouse.my
            else
              if mouse.shift then
                val = ctlpos + ((0.5-val)*2)*0.1
              else
                val = ctlpos + (0.5-val)*2
              end
              local p = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].param
              local min, max = GetParamMinMax_ctl(ctl_select[1].ctl, false) --trctls_table[p].min, trctls_table[p].max
              
              if val < min then val = min end
              if val > max then val = max end
              if val ~= octlval then
                val = math.min(val,nz(maxov_select-0.05,1))
                SetParam4(val)
                local dval = GetParamDisp_Ctl(ctl_select[1].ctl)
                minov_select = val
                ov_disp = dval
                SetParam()                
                octlval = val
                update_ctls = true
              end
            end
          elseif minov_act ~= nil then
            minov_act = nil
            
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].minov = minov_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dirty = true
              trackfxparam_select = ctl_select[i].ctl

              local min, max = GetParamMinMax_ctl(ctl_select[i].ctl)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval = normalize(min, max, ctl_select[i].denorm_defval)
              SetParam3(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval)
            end
          end
          
        elseif mouse.context and mouse.context == contexts.maxov then
          local val = MOUSE_slider(obj.sections[129],mouse.slideoff)
          if val ~= nil then
            if oms ~= mouse.shift then
              oms = mouse.shift
              ctlpos = minov_select
              mouse.slideoff = obj.sections[129].y+obj.sections[129].h/2 - mouse.my
            else
              if mouse.shift then
                val = ctlpos + ((0.5-val)*2)*0.1
              else
                val = ctlpos + (0.5-val)*2
              end
              local p = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].param
              local min, max = GetParamMinMax_ctl(ctl_select[1].ctl, false) --trctls_table[p].min, trctls_table[p].max
              
              if val < min then val = min end
              if val > max then val = max end
              if val ~= octlval then
                val = math.max(val,nz(minov_select+0.05,0))
                SetParam4(val)
                local dval = GetParamDisp_Ctl(ctl_select[1].ctl)
                maxov_select = val
                ov_disp = dval
                SetParam()
                octlval = val
                update_ctls = true
              end
            end
          elseif maxov_act ~= nil then
            maxov_act = nil
            
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].maxov = maxov_select
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].dirty = true
              trackfxparam_select = ctl_select[i].ctl

              local min, max = GetParamMinMax_ctl(ctl_select[i].ctl)
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval = normalize(min, max, ctl_select[i].denorm_defval)
              SetParam3(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].defval)
            end
          end
        
        elseif mouse.context and mouse.context == contexts.cycleknob then
          local val = MOUSE_slider(obj.sections[101],mouse.slideoff)
          if val ~= nil then
            if oms ~= mouse.shift then
              oms = mouse.shift
              ctlpos = cycle_select.val
              mouse.slideoff = obj.sections[101].y+obj.sections[101].h/2 - mouse.my
            else
              if mouse.shift then
                val = ctlpos + ((0.5-val)*2)*0.1
              else
                val = ctlpos + (0.5-val)*2
              end
              local min,max = 0,1
              if strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctlcats == ctlcats.fxparam then
                min, max = GetParamMinMax_ctl(ctl_select[1].ctl)
              end
              if val < min then val = min end
              if val > max then val = max end
              if val ~= octlval then
                SetParam3(val)
                local t = strips[tracks[track_select].strip].track.tracknum
                if strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].tracknum ~= nil then
                  t = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].tracknum
                end
                local cc = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctlcat
                local f = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].fxnum
                local p = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].param
                local dvoff = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].dvaloffset
                local v2 = GetParamValue(cc,t,f,p,ctl_select[1].ctl)
                cycle_select.val = val
                
                if cycle_select.selected then
                  local dispval = GetParamDisp(cc, t, f, p, dvoff,ctl_select[1].ctl)
                  cycle_select[cycle_select.selected].val = v2                  
                  cycle_select[cycle_select.selected].dispval = dispval
                end
                octlval = val
                --SetParam()
                strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].dirty = true
                update_ctls = true
              end
            end
          end
        
        end
        
        if mouse.context and mouse.context == contexts.scaleslider then
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

        if mouse.context and mouse.context == contexts.offsetslider then
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

        if mouse.context and mouse.context == contexts.valoffsetslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[65]),0,1)
          if val ~= nil then
            textoffval_select = val*100 - 50
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textoffval = textoffval_select
            end            
            update_gfx = true
          end
        end

        if mouse.context and mouse.context == contexts.textsizeslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[58]),0,1)
          if val ~= nil then
            textsize_select = (val*35)-2
            for i = 1, #ctl_select do
              strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].textsize = textsize_select
            end            
            update_gfx = true
          end
        end

        if mouse.context and mouse.context == contexts.defvalslider then
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
            
        if mouse.context and mouse.context == contexts.dragctl then
          if math.floor(mouse.mx/settings_gridsize) ~= math.floor(mouse.last_x/settings_gridsize) or math.floor(mouse.my/settings_gridsize) ~= math.floor(mouse.last_y/settings_gridsize) then
            local i
            local scale = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].scale
            local zx, zy = 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].w, 0.5*strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].ctl_info.cellh
            
            if nz(strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].poslock,false) == false then
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
            end
            if #ctl_select > 1 then
              for i = 2, #ctl_select do
                if nz(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].poslock,false) == false then
                  scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
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
            end
            if gfx3_select and #gfx3_select > 0 then
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
  
        if mouse.context and mouse.context == contexts.draglasso then
          if (mouse.mx ~= mouse.last_x or mouse.my ~= mouse.last_y) then
            lasso.r = mouse.mx
            lasso.b = mouse.my
            Lasso_Select()
            if ctl_select ~= nil then
              SetCtlSelectVals()
            end
            SetPosLockCtl()
            update_ctls = true
          end
        elseif lasso ~= nil then
          --Dropped
          if math.abs(lasso.l-lasso.r) < 10 and math.abs(lasso.t-lasso.b) < 10 then
          -- == mouse.mx and lasso.t == mouse.my then
            if ctl_select ~= nil then
              if poslockctl_select then
                mm = '!Lock position'
              else
                mm = 'Lock position'              
              end
              local mstr = 'Duplicate||Align Top|Align Left||'..mm..'||Delete'
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
              elseif res == 2 then
                if #ctl_select > 1 then
                  local y = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y
                  for i = 2, #ctl_select do
                    if nz(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].poslock, false) == false then
                      strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y = y
                      local scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
                      strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ysc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
                                                                                 + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh/2
                                                                                 - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].ctl_info.cellh*scale)/2)
                    end
                  end
                  ReselectSelection()
                  update_gfx = true
                end
              elseif res == 3 then
                if #ctl_select > 1 then
                  local x = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x
                  for i = 2, #ctl_select do
                    if nz(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].poslock, false) == false then
                      strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x = x
                      local scale = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].scale
                      strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].xsc = strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x
                                                                                 + math.floor(strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w/2
                                                                                 - (strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].w*scale)/2)
                    end
                  end
                  ReselectSelection()
                  update_gfx = true
                end
              elseif res == 4 then
                for i = 1, #ctl_select do
                  strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].poslock = not poslockctl_select
                end
                SetPosLockCtl()
              elseif res == 5 then
                DeleteSelectedCtls()
                update_gfx = true
              end
            
            end
          
          end
          
          lasso = nil
          update_ctls = true
        end
      
        if MOUSE_click(obj.sections[48]) then
          if mouse.mx > obj.sections[48].w-40 then
            show_paramlearn = not show_paramlearn
            update_gfx = true
          else           
            trackedit_select = trackedit_select + 1 
            if trackedit_select > #tracks then
              trackedit_select = -1
            end
            PopulateTrackFX()
            PopulateTrackSendsInfo()
            update_gfx = true 
          end
        elseif MOUSE_click_RB(obj.sections[48]) then
          trackedit_select = trackedit_select - 1 
          if trackedit_select < -1 then
            trackedit_select = #tracks
          end
          PopulateTrackFX()
          PopulateTrackSendsInfo()
          update_gfx = true    
        end
        
        if fxmode == 0 then
          if MOUSE_click(obj.sections[41]) then
            local i = math.floor((mouse.my - obj.sections[41].y) / butt_h)-2
            if i == -1 then
              if mouse.mx < obj.sections[41].w/2 then
                flist_offset = flist_offset - F_butt_cnt
                if flist_offset < 0 then
                  flist_offset = 0
                end
              else
                if flist_offset + F_butt_cnt < #trackfx then
                  flist_offset = flist_offset + F_butt_cnt-1
                end          
              end
              update_gfx = true
            elseif trackfx[i + flist_offset] then
              trackfx_select = i + flist_offset
              PopulateTrackFXParams()
              update_gfx = true
            end
          elseif MOUSE_click_RB(obj.sections[41]) then
            local i = math.floor((mouse.my - obj.sections[41].y) / butt_h)-2
            if i == -1 then
            elseif i >= F_butt_cnt then
            elseif trackfx[i + flist_offset] then
              local track = GetTrack(tracks[track_select].tracknum)
              if not reaper.TrackFX_GetOpen(track, i + flist_offset) then
                reaper.TrackFX_Show(track, i + flist_offset, 3)
              end
            end        
          end
      
          if MOUSE_click(obj.sections[42]) then
            local i = math.floor((mouse.my - obj.sections[42].y) / butt_h)-2
            if i == -1 then
              if mouse.mx < obj.sections[42].w/2 then
                plist_offset = plist_offset - P_butt_cnt
                if plist_offset < 0 then
                  plist_offset = 0
                end
              else
                if plist_offset + P_butt_cnt < #trackfxparams then
                  plist_offset = plist_offset + P_butt_cnt
                end          
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
              mouse.context = contexts.dragparam
            end
          end
        elseif fxmode == 1 then
          if MOUSE_click(obj.sections[41]) then
            local i = math.floor((mouse.my - obj.sections[41].y) / butt_h)-2
            if i == -1 then
              if mouse.mx < obj.sections[41].w/2 then
                trctltypelist_offset = trctltypelist_offset - F_butt_cnt
                if trctltypelist_offset < 0 then
                  trctltypelist_offset = 0
                end
              else
                if trctltypelist_offset + F_butt_cnt < #trctltype_table then
                  trctltypelist_offset = trctltypelist_offset + F_butt_cnt-1
                end          
              end
              update_gfx = true
            elseif trctltype_table[i + trctltypelist_offset+1] then
              trctltype_select = i + trctltypelist_offset
              --PopulateTrackFXParams()
              update_gfx = true
            end
          end

          if MOUSE_click(obj.sections[42]) then
            local pcnt = 0
            if trctltype_select == 0 then
              pcnt = #trctls_table
            elseif trctltype_select == 1 then            
              pcnt = (#trsends_table+1)*3
            end
          
            local i = math.floor((mouse.my - obj.sections[42].y) / butt_h)-2
            if i == -1 then
              if mouse.mx < obj.sections[42].w/2 then
                trctlslist_offset = trctlslist_offset - P_butt_cnt
                if trctlslist_offset < 0 then
                  trctlslist_offset = 0
                end
              else
                if trctlslist_offset + P_butt_cnt < #trctls_table-1 then
                  trctlslist_offset = trctlslist_offset + P_butt_cnt
                  if trctlslist_offset > #trctls_table-1 then
                    trctlslist_offset = #trctls_table-1
                  end
                end          
              end
              update_gfx = true
            elseif i >= 0 and i < pcnt then
              if trctltype_select == 0 then
                trctl_select = i + trctlslist_offset+1
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
                mouse.context = contexts.dragparam_tr
              elseif trctltype_select == 1 then
                trctl_select = i + trctlslist_offset+1
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
                mouse.context = contexts.dragparam_snd              
              end
            end
          end
          
        end
                
        if mouse.context and mouse.context == contexts.dragparam then
          dragparam = {x = mouse.mx-ksel_size.w, y = mouse.my-ksel_size.h, type = 'track'}
          reass_param = nil
          if tracks[track_select] and tracks[track_select].strip ~= -1 then
            for i = 1, #strips[tracks[track_select].strip][page].controls do
            
              local xywh 
              xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                      y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                      w = strips[tracks[track_select].strip][page].controls[i].w, 
                      h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}    
              if MOUSE_over(xywh) then
                reass_param = i
                break
              end
            end
          end                    
          update_gfx = true
        
        elseif mouse.context and mouse.context == contexts.dragparamlrn then
          dragparam = {x = mouse.mx-ksel_size.w, y = mouse.my-ksel_size.h, type = 'learn'}
          reass_param = nil
          if tracks[track_select] and tracks[track_select].strip ~= -1 then
            for i = 1, #strips[tracks[track_select].strip][page].controls do
            
              local xywh 
              xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                      y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                      w = strips[tracks[track_select].strip][page].controls[i].w, 
                      h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}    
              if MOUSE_over(xywh) then
                reass_param = i
                break
              end
            end
          end                    
          update_gfx = true
        
        elseif mouse.context and mouse.context == contexts.dragparam_tr then
          dragparam = {x = mouse.mx-ksel_size.w, y = mouse.my-ksel_size.h, type = 'trctl'}
          reass_param = nil
          if tracks[track_select] and tracks[track_select].strip ~= -1 then
            for i = 1, #strips[tracks[track_select].strip][page].controls do
            
              local xywh 
              xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                      y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                      w = strips[tracks[track_select].strip][page].controls[i].w, 
                      h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}    
              if MOUSE_over(xywh) then
                reass_param = i
                break
              end
            end
          end                    
          update_gfx = true

        elseif mouse.context and mouse.context == contexts.dragparam_snd then
          dragparam = {x = mouse.mx-ksel_size.w, y = mouse.my-ksel_size.h, type = 'trsnd'}
          reass_param = nil
          if tracks[track_select] and tracks[track_select].strip ~= -1 then
            for i = 1, #strips[tracks[track_select].strip][page].controls do
            
              local xywh 
              xywh = {x = strips[tracks[track_select].strip][page].controls[i].x - surface_offset.x +obj.sections[10].x, 
                      y = strips[tracks[track_select].strip][page].controls[i].y - surface_offset.y +obj.sections[10].y, 
                      w = strips[tracks[track_select].strip][page].controls[i].w, 
                      h = strips[tracks[track_select].strip][page].controls[i].ctl_info.cellh}    
              if MOUSE_over(xywh) then
                reass_param = i
                break
              end
            end
          end                    
          update_gfx = true
          
        elseif dragparam ~= nil then
          --Dropped
          if dragparam.type == 'track' then
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
                  strips[tracks[track_select].strip][page].controls[reass_param].c_id = GenID()
                  if tracks[trackedit_select].tracknum ~= tracks[track_select].tracknum then
                    strips[tracks[track_select].strip][page].controls[reass_param].tracknum=tracks[trackedit_select].tracknum
                    strips[tracks[track_select].strip][page].controls[reass_param].trackguid=tracks[trackedit_select].guid
                  else
                    strips[tracks[track_select].strip][page].controls[reass_param].tracknum=nil
                    strips[tracks[track_select].strip][page].controls[reass_param].trackguid=nil                  
                  end
                  strips[tracks[track_select].strip][page].controls[reass_param].ctlcat = ctlcats.fxparam
                  strips[tracks[track_select].strip][page].controls[reass_param].fxname=trackfx[trackfx_select].name
                  strips[tracks[track_select].strip][page].controls[reass_param].fxguid=trackfx[trackfx_select].guid
                  strips[tracks[track_select].strip][page].controls[reass_param].fxnum=trackfx[trackfx_select].fxnum
                  strips[tracks[track_select].strip][page].controls[reass_param].fxfound = true
                  strips[tracks[track_select].strip][page].controls[reass_param].param = trackfxparam_select
                  strips[tracks[track_select].strip][page].controls[reass_param].param_info = trackfxparams[trackfxparam_select]
                  strips[tracks[track_select].strip][page].controls[reass_param].val = GetParamValue(ctlcats.fxparam,
                                                                                                     tracks[trackedit_select].tracknum,
                                                                                                     trackfx[trackfx_select].fxnum,
                                                                                                     trackfxparam_select, reass_param)
                  strips[tracks[track_select].strip][page].controls[reass_param].defval = GetParamValue(ctlcats.fxparam,
                                                                                                     tracks[trackedit_select].tracknum,
                                                                                                     trackfx[trackfx_select].fxnum,
                                                                                                     trackfxparam_select, reass_param)
                else
                  OpenMsgBox(1, 'You cannot reassign multiple controls at once.', 1)
                end
                tfxp_sel = nil
              end
            end
          elseif dragparam.type == 'learn' then
            if reass_param == nil then
              if dragparam.x+ksel_size.w > obj.sections[10].x and dragparam.x+ksel_size.w < obj.sections[10].x+obj.sections[10].w and dragparam.y+ksel_size.h > obj.sections[10].y and dragparam.y+ksel_size.h < obj.sections[10].y+obj.sections[10].h then
                if not MOUSE_over(obj.sections[115]) then
                  Strip_AddParam()
                end
              end
            else
              if dragparam.x+ksel_size.w > obj.sections[10].x and dragparam.x+ksel_size.w < obj.sections[10].x+obj.sections[10].w and dragparam.y+ksel_size.h > obj.sections[10].y and dragparam.y+ksel_size.h < obj.sections[10].y+obj.sections[10].h then
                if not MOUSE_over(obj.sections[115]) then
                
                  if last_touch_fx.tracknum ~= tracks[track_select].tracknum then
                    strips[tracks[track_select].strip][page].controls[reass_param].tracknum=last_touch_fx.tracknum
                    strips[tracks[track_select].strip][page].controls[reass_param].trackguid=last_touch_fx.trguid
                  else
                    strips[tracks[track_select].strip][page].controls[reass_param].tracknum=nil
                    strips[tracks[track_select].strip][page].controls[reass_param].trackguid=nil                  
                  end
                  strips[tracks[track_select].strip][page].controls[reass_param].c_id = GenID()
                  strips[tracks[track_select].strip][page].controls[reass_param].ctlcat = ctlcats.fxparam
                  strips[tracks[track_select].strip][page].controls[reass_param].fxname=last_touch_fx.fxname
                  strips[tracks[track_select].strip][page].controls[reass_param].fxguid=last_touch_fx.fxguid
                  strips[tracks[track_select].strip][page].controls[reass_param].fxnum=last_touch_fx.fxnum
                  strips[tracks[track_select].strip][page].controls[reass_param].fxfound = true
                  strips[tracks[track_select].strip][page].controls[reass_param].param = last_touch_fx.paramnum
                  strips[tracks[track_select].strip][page].controls[reass_param].param_info = {paramname = last_touch_fx.prname,
                                                                                               paramnum = last_touch_fx.paramnum}
                  strips[tracks[track_select].strip][page].controls[reass_param].val = GetParamValue(ctlcats.fxparam,
                                                                                                     last_touch_fx.tracknum,
                                                                                                     last_touch_fx.fxnum,
                                                                                                     last_touch_fx.paramnum, reass_param)
                  strips[tracks[track_select].strip][page].controls[reass_param].defval = GetParamValue(ctlcats.fxparam,
                                                                                                     last_touch_fx.tracknum,
                                                                                                     last_touch_fx.fxnum,
                                                                                                     last_touch_fx.paramnum, reass_param)
                  
                end
              end
            end
                  
          elseif dragparam.type == 'trctl' or dragparam.type == 'trsnd' then
            if reass_param == nil then
              if dragparam.x+ksel_size.w > obj.sections[10].x and dragparam.x+ksel_size.w < obj.sections[10].x+obj.sections[10].w and dragparam.y+ksel_size.h > obj.sections[10].y and dragparam.y+ksel_size.h < obj.sections[10].y+obj.sections[10].h then
                trackfxparam_select = i
                Strip_AddParam()              
              end
            else
              local cnt = 1
              if cnt <= 1 then
                if tracks[trackedit_select].tracknum ~= tracks[track_select].tracknum then
                  strips[tracks[track_select].strip][page].controls[reass_param].tracknum=tracks[trackedit_select].tracknum
                  strips[tracks[track_select].strip][page].controls[reass_param].trackguid=tracks[trackedit_select].guid
                else
                  strips[tracks[track_select].strip][page].controls[reass_param].tracknum=nil
                  strips[tracks[track_select].strip][page].controls[reass_param].trackguid=nil                  
                end
                strips[tracks[track_select].strip][page].controls[reass_param].c_id = GenID()
                strips[tracks[track_select].strip][page].controls[reass_param].fxguid=nil
                strips[tracks[track_select].strip][page].controls[reass_param].fxnum=nil
                strips[tracks[track_select].strip][page].controls[reass_param].fxfound = true
                strips[tracks[track_select].strip][page].controls[reass_param].param = trctl_select

                if dragparam.type == 'trctl' then
                  strips[tracks[track_select].strip][page].controls[reass_param].ctlcat = ctlcats.trackparam
                  strips[tracks[track_select].strip][page].controls[reass_param].fxname='Track Parameter'
                  strips[tracks[track_select].strip][page].controls[reass_param].param_info = {paramname = 'Track '..trctls_table[trctl_select].name,
                                                                                               paramnum = trctl_select}
                  strips[tracks[track_select].strip][page].controls[reass_param].val = GetParamValue(ctlcats.trackparam,
                                                                                                      tracks[trackedit_select].tracknum,
                                                                                                      nil,
                                                                                                      trctl_select, nil)
                  strips[tracks[track_select].strip][page].controls[reass_param].defval = strips[tracks[track_select].strip][page].controls[reass_param].val 
                  
                elseif dragparam.type == 'trsnd' then
                  local sidx = math.floor((trctl_select-1) / 3)
                  local pidx = (trctl_select-1) % 3 +1
                  strips[tracks[track_select].strip][page].controls[reass_param].ctlcat = ctlcats.tracksend
                  strips[tracks[track_select].strip][page].controls[reass_param].fxname='Track Send'
                  strips[tracks[track_select].strip][page].controls[reass_param].param_info = {paramname = trsends_table[sidx][pidx].name,
                                                                                               paramnum = trctl_select,
                                                                                               paramidx = trsends_table[sidx].idx,
                                                                                               paramstr = trsends_table[sidx][pidx].parmname,
                                                                                               paramdesttrnum = trsends_table[sidx].desttracknum,
                                                                                               paramdestguid = trsends_table[sidx].desttrackguid,
                                                                                               paramdestchan = trsends_table[sidx].dstchan,
                                                                                               paramsrcchan = trsends_table[sidx].srcchan}
                  strips[tracks[track_select].strip][page].controls[reass_param].val = GetParamValue(ctlcats.tracksend,
                                                                                                      tracks[trackedit_select].tracknum,
                                                                                                      nil,
                                                                                                      trctl_select, reass_param)
                  strips[tracks[track_select].strip][page].controls[reass_param].defval = strips[tracks[track_select].strip][page].controls[reass_param].val
                end
              else
                OpenMsgBox(1, 'You cannot reassign multiple controls at once.', 1)
              end
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
          ctl_page = 0
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
      
        local clicklblopts = false
        if gfx2_select ~= nil and show_lbloptions and (MOUSE_click(obj.sections[49]) or MOUSE_click_RB(obj.sections[49])) then
          
          -- LBL OPTIONS
          clicklblopts = true
        
          if MOUSE_click(obj.sections[140]) then
            EditLabel(7,gfx_text_select)
          end          

          if MOUSE_click(obj.sections[147]) then
            EditFont()
          end          
        
          if MOUSE_click(obj.sections[142]) then
            local retval, c = reaper.GR_SelectColor(_,ConvertColorString(gfx_textcol_select))
            if retval ~= 0 then
              gfx_textcol_select = ConvertColor(c)
              strips[tracks[track_select].strip][page].graphics[gfx2_select].text_col = gfx_textcol_select
              update_gfx = true
            end
          end
          
          if MOUSE_click(obj.sections[143]) then
            gfx_font_select.bold = not gfx_font_select.bold
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.bold = gfx_font_select.bold
            update_gfx = true
          end

          if MOUSE_click(obj.sections[144]) then
            gfx_font_select.italics = not gfx_font_select.italics
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.italics = gfx_font_select.italics
            update_gfx = true
          end

          if MOUSE_click(obj.sections[145]) then
            gfx_font_select.underline = not gfx_font_select.underline
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.underline = gfx_font_select.underline
            update_gfx = true
          end

          if MOUSE_click(obj.sections[146]) then
            gfx_font_select.shadow = not gfx_font_select.shadow
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow = gfx_font_select.shadow
            update_gfx = true
          end
          
          if mouse.context == nil and MOUSE_click(obj.sections[141]) then mouse.context = contexts.textsizeslider 
          elseif mouse.context == nil and MOUSE_click(obj.sections[148]) then mouse.context = contexts.shadxslider
          elseif mouse.context == nil and MOUSE_click(obj.sections[149]) then mouse.context = contexts.shadyslider
          elseif mouse.context == nil and MOUSE_click(obj.sections[150]) then mouse.context = contexts.shadaslider end
          
        end
      
        if mouse.context and mouse.context == contexts.textsizeslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[141]),0,1)
          if val ~= nil then
            gfx_font_select.size = F_limit((val*250),8,250)
            --for i = 1, #ctl_select do
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.size = gfx_font_select.size
            --end            
            update_gfx = true
          end
        elseif mouse.context and mouse.context == contexts.shadxslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[148]),0,1)
          if val ~= nil then
            gfx_font_select.shadow_x = math.floor((val*30)-15)
            --for i = 1, #ctl_select do
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_x = gfx_font_select.shadow_x
            --end            
            update_gfx = true
          end
        elseif mouse.context and mouse.context == contexts.shadyslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[149]),0,1)
          if val ~= nil then
            gfx_font_select.shadow_y = math.floor((val*30)-15)
            --for i = 1, #ctl_select do
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_y = gfx_font_select.shadow_y
            --end            
            update_gfx = true
          end
        elseif mouse.context and mouse.context == contexts.shadaslider then
          local val = F_limit(MOUSE_sliderHBar(obj.sections[150]),0,1)
          if val ~= nil then
            gfx_font_select.shadow_a = val
            --for i = 1, #ctl_select do
            strips[tracks[track_select].strip][page].graphics[gfx2_select].font.shadow_a = gfx_font_select.shadow_a
            --end            
            update_gfx = true
          end
        end
        
        if MOUSE_click(obj.sections[44]) then
          local i = math.floor((mouse.my - obj.sections[44].y) / butt_h)-1
          
          if i == -1 then
            if mouse.mx < obj.sections[44].w/2 then
              glist_offset = glist_offset - G_butt_cnt
              if glist_offset < 0 then
                glist_offset = 0
              end
            else
              if glist_offset + G_butt_cnt < #graphics_files then
                glist_offset = glist_offset + G_butt_cnt
              end
            end
            update_gfx = true
          elseif graphics_files[i + glist_offset] then
            gfx_select = i + glist_offset
            
            --load temp image
            gfx.loadimg(1023,graphics_path..graphics_files[gfx_select].fn)
            draggfx_w, draggfx_h = gfx.getimgdim(1023)
            
            update_gfx = true
            mouse.context = contexts.draggfx
          end
          
        end
        
        if mouse.context and mouse.context == contexts.draggfx then
          draggfx = {x = mouse.mx - draggfx_w/2, y = mouse.my - draggfx_h/2}
          update_gfx = true
        elseif draggfx ~= nil then
          --Dropped
          if mouse.mx > obj.sections[10].x and mouse.mx < obj.sections[10].x+obj.sections[10].w and mouse.my > obj.sections[10].y and mouse.my < obj.sections[10].y+obj.sections[10].h then
            Strip_AddGFX(gfxtype.img)
          end
          
          draggfx = nil
          update_gfx = true
        end
      
        if mouse.mx > obj.sections[10].x and clicklblopts == false then
          if strips and tracks[track_select] and strips[tracks[track_select].strip] then
          
            if gfx2_select ~= nil then
            
              local selrect = CalcGFXSelRect()
              selrect.x = selrect.x - surface_offset.x + obj.sections[10].x
              selrect.y = selrect.y - surface_offset.y + obj.sections[10].y
              local xywh = {x = selrect.x+selrect.w-5,
                            y = selrect.y+selrect.h/2-5,
                            w = 10,
                            h = 10}
              if mouse.context == nil and MOUSE_click(xywh) then
                if poslock_select == false then
                  mouse.context = contexts.stretch_x
                  gfx2_stretch = {mx = mouse.mx, sw = strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchw}
                end
              end

              local xywh = {x = selrect.x+selrect.w/2-5,
                            y = selrect.y+selrect.h-5,
                            w = 10,
                            h = 10}
              if mouse.context == nil and MOUSE_click(xywh) then
                if poslock_select == false then
                  mouse.context = contexts.stretch_y
                  gfx2_stretch = {my = mouse.my, sh = strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchh}
                end
              end

              local xywh = {x = selrect.x+selrect.w-5,
                            y = selrect.y+selrect.h-5,
                            w = 10,
                            h = 10}
              if mouse.context == nil and MOUSE_click(xywh) then
                if poslock_select == false then
                  mouse.context = contexts.stretch_xy
                  gfx2_stretch = {mx = mouse.mx, my = mouse.my, sw = strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchw,
                                                                sh = strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchh}
                end
              end
            
              if mouse.context and mouse.context == contexts.stretch_x then
              
                strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchw = math.max(math.floor((gfx2_stretch.sw + (mouse.mx-gfx2_stretch.mx))/settings_gridsize)*settings_gridsize,2)
                update_gfx = true
              
              elseif mouse.context and mouse.context == contexts.stretch_y then
              
                strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchh =  math.max(math.floor((gfx2_stretch.sh + (mouse.my-gfx2_stretch.my))/settings_gridsize)*settings_gridsize,2)
                update_gfx = true
                
              elseif mouse.context and mouse.context == contexts.stretch_xy then
              
                strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchw = math.max(math.floor((gfx2_stretch.sw + (mouse.mx-gfx2_stretch.mx))/settings_gridsize)*settings_gridsize,2)
                strips[tracks[track_select].strip][page].graphics[gfx2_select].stretchh = math.max(math.floor((gfx2_stretch.sh + (mouse.my-gfx2_stretch.my))/settings_gridsize)*settings_gridsize,2)
                update_gfx = true

              end            
            
            end
            
            local clickxywh = false
            if mouse.context == nil then
              for i = #strips[tracks[track_select].strip][page].graphics,1,-1 do
                local xywh
                xywh = {x = strips[tracks[track_select].strip][page].graphics[i].x - surface_offset.x + obj.sections[10].x, 
                        y = strips[tracks[track_select].strip][page].graphics[i].y - surface_offset.y + obj.sections[10].y, 
                        w = strips[tracks[track_select].strip][page].graphics[i].stretchw, 
                        h = strips[tracks[track_select].strip][page].graphics[i].stretchh}
                
                if xywh.w < 16 then
                  xywh.x = xywh.x - 8
                  xywh.w = 16
                end
                if xywh.h < 16 then 
                  xywh.y = xywh.y - 8
                  xywh.h = 16
                end
                
                if MOUSE_click(xywh) then
                  gfx2_select = i              

                  poslock_select = nz(strips[tracks[track_select].strip][page].graphics[gfx2_select].poslock,false)
                  
                  mouse.context = contexts.draggfx2
                  draggfx2 = 'draggfx'
                  dragoff = {x = mouse.mx - strips[tracks[track_select].strip][page].graphics[gfx2_select].x - surface_offset.x,
                             y = mouse.my - strips[tracks[track_select].strip][page].graphics[gfx2_select].y - surface_offset.y}
                  
                  if strips[tracks[track_select].strip][page].graphics[gfx2_select].gfxtype == gfxtype.txt then
                    show_lbloptions = true
                    SetGfxSelectVals()
                  else
                    show_lbloptions = false
                  end
                  update_gfx = true
                  clickxywh = true
                  break
                elseif MOUSE_click_RB(xywh) then
                  GFXMenu()
                  clickxywh = true
                  break
                end
              end

              if clickxywh == false and MOUSE_click_RB(obj.sections[10]) then
                GFXMenu()
              end
            end
            
          end
        end
                  
        if mouse.context and mouse.context == contexts.draggfx2 then
          if math.floor(mouse.mx/settings_gridsize) ~= math.floor(mouse.last_x/settings_gridsize) or math.floor(mouse.my/settings_gridsize) ~= math.floor(mouse.last_y/settings_gridsize) then
            local i
            if poslock_select == false then
            
              strips[tracks[track_select].strip][page].graphics[gfx2_select].x = math.floor((mouse.mx - surface_offset.x)/settings_gridsize)*settings_gridsize 
                                                                                 - math.floor((dragoff.x)/settings_gridsize)*settings_gridsize
              strips[tracks[track_select].strip][page].graphics[gfx2_select].y = math.floor((mouse.my - surface_offset.y)/settings_gridsize)*settings_gridsize 
                                                                                 - math.floor((dragoff.y)/settings_gridsize)*settings_gridsize
            end
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
                    mouse.context = contexts.dragctl
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
        
        if mouse.context and mouse.context == contexts.dragctl then
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
            if mouse.mx < obj.sections[47].w/2 then
              sflist_offset = sflist_offset - SF_butt_cnt
              if sflist_offset < 0 then
                sflist_offset = 0
              end
            else
              if sflist_offset + SF_butt_cnt-1 < #strip_folders then
                sflist_offset = sflist_offset + SF_butt_cnt
              end
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
            if mouse.mx < obj.sections[46].w/2 then
              slist_offset = slist_offset - S_butt_cnt
              if slist_offset < 0 then
                slist_offset = 0
              end
            else
              if slist_offset + S_butt_cnt-1 < #strip_files then
                slist_offset = slist_offset + S_butt_cnt-1
              end
            end
            update_gfx = true
          elseif strip_files[i-1 + slist_offset] then
            strip_select = i-1 + slist_offset
            --gen preview
            loadstrip = LoadStrip(strip_select)
            if loadstrip then
              GenStripPreview(gui, loadstrip.strip)
                        
              mouse.context = contexts.dragstrip
            end
            update_gfx = true
          end
          
        elseif MOUSE_click_RB(obj.sections[46]) then
        
          if strip_select then
            mstr = 'Set Default'
            gfx.x, gfx.y = mouse.mx, mouse.my
            res = OpenMenu(mstr)
            if res ~= 0 then
              if res == 1 then
                
                strip_default = {strip_select = strip_select,
                                 stripfol_select = stripfol_select}
                                 
              end
            end
          end        
          
        
        end
        
        if mouse.context and mouse.context == contexts.dragstrip then
          if mouse.mx ~= mouse.last_x or mouse.my ~= mouse.last_y then
            dragstrip = {x = mouse.mx, y = mouse.my}
            update_gfx = true
          end
        elseif dragstrip ~= nil then
          --Dropped
          image_count = image_count_add
          if dragstrip.x > obj.sections[10].x and dragstrip.x < obj.sections[10].w and dragstrip.y > obj.sections[10].y and dragstrip.y < obj.sections[10].h then
            Strip_AddStrip(loadstrip, dragstrip.x-obj.sections[10].x, dragstrip.y-obj.sections[10].y)
          end
          
          --loadstrip = nil
          loadstrip = nil
          dragstrip = nil
          ctl_select = nil
          update_gfx = true
        end
        
      end
      
      if MOUSE_click(obj.sections[13]) then
        if submode ~= 0 or (submode == 0 and mouse.mx < obj.sections[13].x + obj.sections[13].w - 30) then
          ctl_select = nil
          gfx2_select = nil
          gfx3_select = nil
          submode = submode + 1
          if submode+1 > #submode_table then
            submode = 0
          end
          update_gfx = true
        elseif submode == 0 and mouse.mx > obj.sections[13].x + obj.sections[13].w - 30 then
         
          fxmode = (fxmode + 1) % 2
          update_gfx = true
         
        end

      elseif MOUSE_click_RB(obj.sections[13]) then
        --if submode ~= 0 or (submode == 0 and mouse.mx > 30) then
          ctl_select = nil
          gfx2_select = nil
          gfx3_select = nil
          submode = submode - 1
          if submode < 0 then
            submode = #submode_table-1
          end
          update_gfx = true
        --[[else
          trackedit_select = trackedit_select - 1 
          if trackedit_select < -1 then
            trackedit_select = #tracks
          end
          PopulateTrackFX()
          update_gfx = true    
        end]]
      end          
    end
    
    if mouse.context == nil then
      if ((submode == 0 and ctl_select ~= nil) and (MOUSE_click(obj.sections[45]) or (MOUSE_click(obj.sections[100]) and show_cycleoptions))) or 
         ((submode == 1 and gfx2_select ~= nil) and (MOUSE_click(obj.sections[49]) and show_lbloptions)) then
      elseif mouse.mx > obj.sections[10].x then
      
        if MOUSE_click(obj.sections[10]) then
          if noscroll == false then
            mouse.context = "dragsurface"
            surx = surface_offset.x
            sury = surface_offset.y
            mmx = mouse.mx
            mmy = mouse.my
          end
          ctl_select = nil
          show_cycleoptions = false
          gfx2_select = nil
          gfx3_select = nil
          update_gfx = true
        end

      end    
    end
    if mouse.context and mouse.context == "dragsurface" then
      if noscroll == false and settings_locksurface == false then
      
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
          --if locky == false then
          --  surface_offset.x = F_limit(surx + offx,0-math.ceil(obj.sections[10].w*0.25),surface_size.w - math.ceil(obj.sections[10].w*0.75))
          --else
            surface_offset.x = F_limit(surx + offx,0,surface_size.w - obj.sections[10].w)        
          --end
        end
        
        if offy ~= nil then
          --if lockx == false then
          --  surface_offset.y = F_limit(sury + offy,0-math.ceil(obj.sections[10].h*0.25),surface_size.h - math.ceil(obj.sections[10].h*0.75))
          --else
            surface_offset.y = F_limit(sury + offy,0,surface_size.h - obj.sections[10].h)        
          --end
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
    end
    
    if settings_mousewheelknob == false and gfx.mouse_wheel ~= 0 then
      if noscroll == false then
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
              --surface_offset.y = F_limit(surface_offset.y - v * 50,0-math.ceil(obj.sections[10].h*0.25),surface_size.h - math.ceil(obj.sections[10].h*0.75))
              surface_offset.y = F_limit(surface_offset.y - v * 50,0,surface_size.h - obj.sections[10].h)        
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
      else
        if ctl_select then
          ctl_select = nil
          update_gfx = true
        end
      
      end
      gfx.mouse_wheel = 0
    end
        
    end

    if not mouse.LB and not mouse.RB then mouse.context = nil end
    if show_cycleoptions == false then cycle_editmode = false end
    
    local char = gfx.getchar() 
    if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
    --if char == 27 then quit() end     
    --if char ~= -1 then reaper.defer(run) else quit() end
    if char>=0 and char~=27 then reaper.defer(run) end
    gfx.update()
    mouse.last_LB = mouse.LB
    mouse.last_RB = mouse.RB
    mouse.last_x = mouse.mx
    mouse.last_y = mouse.my
    if mouse.LB then
      mouse.lastLBclicktime = rt
    end
    gfx.mouse_wheel = 0
    if ctl_select then ctls = true else ctls = false end
      
  end
  
  function ReselectSelection()
  
    local tbl = {}
    tbl[1] = {ctl = ctl_select[1].ctl}
    for i = 2, #ctl_select do
    
      tbl[i] = {}
      tbl[i].ctl = ctl_select[i].ctl
      tbl[i].relx = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].x - strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].x    
      tbl[i].rely = strips[tracks[track_select].strip][page].controls[ctl_select[1].ctl].y - strips[tracks[track_select].strip][page].controls[ctl_select[i].ctl].y
    
    end
    
    ctl_select = tbl
      
  end
  
  function GetLastTouchedFX(lastfx)
    
    local rt, tr, fx, pr = reaper.GetLastTouchedFX()
    if rt == true then
      if lastfx == nil or (lastfx ~= nil and (tr-1 ~= lastfx.tracknum or fx ~= lastfx.fxnum or pr ~= lastfx.paramnum)) then
        local track = GetTrack(tr-1)
        if track ~= nil then
          local tn = reaper.GetTrackState(track)
          local trg = reaper.GetTrackGUID(track)
          local _, fxn = reaper.TrackFX_GetFXName(track, fx, '')
          local fxg = reaper.TrackFX_GetFXGUID(track, fx)
          local _, prn = reaper.TrackFX_GetParamName(track, fx, pr, '')
          lastfx = {tracknum = tr-1,
                    trguid = trg,
                    fxnum = fx,
                    paramnum = pr,
                    trname = tn,
                    fxname = fxn,
                    fxguid = fxg,
                    prname = prn}
          update_gfx = true
        end
      end
      return lastfx
    else
      return lastfx
    end
  
  end
  
  function Cycle_InitData()
  
    if cycle_select.statecnt > 0 then

      trackfxparam_select = ctl_select[1].ctl
      local tracknum = strips[tracks[track_select].strip].track.tracknum
      if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum ~= nil then
        tracknum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum
      end
      local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
      local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
      local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
      local dvoff = strips[tracks[track_select].strip][page].controls[trackfxparam_select].dvaloffset
      for i = 1, cycle_select.statecnt do      
        if cycle_select[i] == nil or (cycle_select[i] and cycle_select[i].dispval == nil) then
          SetParam3(cycle_select.val)
          cycle_select[i] = {val = cycle_select.val, dispval = GetParamDisp(cc, tracknum, fxnum, param, dvoff,trackfxparam_select)}
        end
      end
      cycle_select.selected = cycle_select.statecnt
      SetParam()
    
    end
  
  end
  
  function Cycle_CopySelectIn(ctl)
  
    local cd = {}
    if strips[tracks[track_select].strip][page].controls[ctl].cycledata then
      cd = strips[tracks[track_select].strip][page].controls[ctl].cycledata
      local co = {statecnt = cd.statecnt,
                  selected = cd.selected,
                  mapptof = cd.mapptof,
                  val = 0,
                  {}}
      for i = 1, max_cycle do
        if cd[i] then
          co[i] = {val = cd[i].val, dispval = cd[i].dispval}
        end
      end
      return co
    else
      return {statecnt = 0,mapptof = false,val = 0,nil}
    end    
  end
  
  function Cycle_CopySelectOut()
  
    local cd = {}
    if cycle_select then
      cd = cycle_select
      local co = {statecnt = cd.statecnt,
                  selected = cd.selected,
                  mapptof = cd.mapptof,
                  {}}
      for i = 1, max_cycle do
        if cd[i] then
          co[i] = {val = cd[i].val, dispval = cd[i].dispval}
        end
      end
      return co
    else
      return {statecnt = 0,mapptof = false,pos = 1,{}}
    end    
  end
  
  function Cycle_Norm(v, c)
  
    if c then
    
      local cc = strips[tracks[track_select].strip][page].controls[c].ctlcat
      if cc == ctlcats.fxparam then
        local min, max = GetParamMinMax_ctl(c)
        return normalize(min, max, v)
      else
        local min, max = GetParamMinMax_ctl(c)
        return F_limit(v,min,max)
      end
    
    end
  
  end
  
  function Cycle_Auto()
  
    trackfxparam_select = ctl_select[1].ctl
    local v, v2 = 0

    local tracknum = strips[tracks[track_select].strip].track.tracknum
    if strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum ~= nil then
      tracknum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].tracknum
    end
    local cc = strips[tracks[track_select].strip][page].controls[trackfxparam_select].ctlcat
    local fxnum = strips[tracks[track_select].strip][page].controls[trackfxparam_select].fxnum
    local param = strips[tracks[track_select].strip][page].controls[trackfxparam_select].param
    local dvoff = strips[tracks[track_select].strip][page].controls[trackfxparam_select].dvaloffset
    
    SetParam3(v)
    local dval = GetParamDisp(cc, tracknum, fxnum, param, dvoff,trackfxparam_select)
    local stcnt = 1
    local ndval
    
    cycle_temp = {}
    cycle_temp[1] = {val = 0, dispval = dval}
    
    for v = 0.01, 1, 0.01 do
      
      SetParam3(v)
      ndval = GetParamDisp(cc, tracknum, fxnum, param, dvoff,trackfxparam_select)
      if ndval ~= dval then
        dval = ndval
        cycle_temp[#cycle_temp+1] = {val = v, dispval = dval}
        stcnt = stcnt + 1
      end
    
    end
  
    if stcnt > max_cycle then
      OpenMsgBox(1, 'Too many values.', 1)
    else
      for i = 1, max_cycle do
        cycle_select[i] = cycle_temp[i]
      end
      cycle_select.statecnt = stcnt
    end
    SetParam()
  
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
  
    local tbl = {ctlcat=strips[tracks[track_select].strip][page].controls[c].ctlcat,
                 fxname=strips[tracks[track_select].strip][page].controls[c].fxname,
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
                 cycledata = strips[tracks[track_select].strip][page].controls[c].cycledata,
                 id = strips[tracks[track_select].strip][page].controls[c].id,
                 tracknum = strips[tracks[track_select].strip][page].controls[c].tracknum,
                 trackguid = strips[tracks[track_select].strip][page].controls[c].trackguid,
                 dvaloffset = strips[tracks[track_select].strip][page].controls[c].dvaloffset,
                 minov = strips[tracks[track_select].strip][page].controls[c].minov,
                 maxov = strips[tracks[track_select].strip][page].controls[c].maxov,
                 membtn = {state = strips[tracks[track_select].strip][page].controls[c].membtn.state,
                           mem = strips[tracks[track_select].strip][page].controls[c].membtn.mem},
                 scalemode = strips[tracks[track_select].strip][page].controls[c].scalemode,
                 framemode = strips[tracks[track_select].strip][page].controls[c].framemode,
                 c_id = strips[tracks[track_select].strip][page].controls[c].c_id
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
    --[[if e.sel ~= 0 then
      local sc,ec=e.caret,e.caret+e.sel
      if sc > ec then sc,ec=ec,sc end
      local sx=gfx.measurestr(string.sub(e.text, 0, sc))
      local ex=gfx.measurestr(string.sub(e.text, 0, ec))
      setcolor(e.txtcol)
      gfx.rect(ox+sx, oy, ex-sx, h, true)
      setcolor(e.bgcol)
      gfx.x,gfx.y=ox+sx,oy
      gfx.drawstr(string.sub(e.text, sc+1, ec))
    end]]
    if e.hasfocus == true then
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
    --e.hasfocus=
    --  gfx.mouse_x >= editbox.x and gfx.mouse_x < editbox.x+editbox.w and
    --  gfx.mouse_y >= editbox.y and gfx.mouse_y < editbox.y+editbox.h    
    if e.hasfocus then
      e.caret=editbox_getcaret(e) 
      e.cursstate=0
    end
    e.sel=0 
  end
  
  function editbox_onmousedoubleclick(e)
    local len=string.len(e.text)
    e.caret=len ; --e.sel=-len
  end
  
  function editbox_onmousemove(e)
    e.sel=editbox_getcaret(e)-e.caret
  end
  
  function editbox_onchar(e, c)
    --[[if e.sel ~= 0 then
      local sc,ec=e.caret,e.caret+e.sel
      if sc > ec then sc,ec=ec,sc end
      e.text=string.sub(e.text,1,sc)..string.sub(e.text,ec+1)
      e.sel=0
    end]]
    if c == 0x6C656674 then -- left arrow
      if e.caret > 0 then e.caret=e.caret-1 end
    elseif c == 0x72676874 then -- right arrow
      if e.caret < string.len(e.text) then e.caret=e.caret+1 end
    elseif c == 8 then -- backspace
      if e.caret > 0 then 
        e.text=string.sub(e.text,1,e.caret-1)..string.sub(e.text,e.caret+1)
        e.caret=e.caret-1
      end
    elseif c == 13 then
      EB_Enter = true
    elseif c >= 32 and c <= 125 and string.len(e.text) < e.maxlen then
      e.text=string.format("%s%c%s", 
        string.sub(e.text,1,e.caret), c, string.sub(e.text,e.caret+1))
      e.caret=e.caret+1
    end
  end
  
  function mb_onchar(c)
  
    if c == 13 then
      MB_Enter = true
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
        settings_locksurface = tobool(nz(GPES('locksurface',true),false))
      
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
                                                c_id = tonumber(nz(GPES(key..'cid',true),GenID() )),
                                                ctlcat = tonumber(nz(GPES(key..'ctlcat',true),0)),
                                                fxname = GPES(key..'fxname'),
                                                fxguid = GPES(key..'fxguid'),
                                                fxnum = tonumber(GPES(key..'fxnum',true)),
                                                fxfound = tobool(GPES(key..'fxfound')),
                                                param = tonumber(GPES(key..'param')),
                                                param_info = {
                                                              paramname = GPES(key..'param_info_name'),
                                                              paramnum = tonumber(GPES(key..'param_info_paramnum')),
                                                              paramidx = GPES(key..'param_info_idx',true),
                                                              paramstr = GPES(key..'param_info_str',true),
                                                              paramdestguid = GPES(key..'param_info_guid',true),
                                                              paramdestchan = tonumber(GPES(key..'param_info_chan',true)),
                                                              paramsrcchan = tonumber(GPES(key..'param_info_srcchan',true))
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
                                                cycledata = {statecnt = 0,{}},
                                                id = deconvnum(GPES(key..'id',true)),
                                                scalemode = tonumber(nz(GPES(key..'scalemodex',true),8)),
                                                framemode = tonumber(nz(GPES(key..'framemodex',true),1)),
                                                poslock = tobool(nz(GPES(key..'poslock',true),false))
                                               }
                    if strips[ss][p].controls[c].maxdp == nil or (strips[ss][p].controls[c].maxdp and strips[ss][p].controls[c].maxdp == '') then
                      strips[ss][p].controls[c].maxdp = -1
                    end
                    strips[ss][p].controls[c].xsc = strips[ss][p].controls[c].x + strips[ss][p].controls[c].w/2 - (strips[ss][p].controls[c].w*strips[ss][p].controls[c].scale)/2
                    strips[ss][p].controls[c].ysc = strips[ss][p].controls[c].y + strips[ss][p].controls[c].ctl_info.cellh/2 - (strips[ss][p].controls[c].ctl_info.cellh*strips[ss][p].controls[c].scale)/2
                    strips[ss][p].controls[c].wsc = strips[ss][p].controls[c].w*strips[ss][p].controls[c].scale
                    strips[ss][p].controls[c].hsc = strips[ss][p].controls[c].ctl_info.cellh*strips[ss][p].controls[c].scale
                    
                    strips[ss][p].controls[c].tracknum = tonumber(GPES(key..'tracknum',true))
                    strips[ss][p].controls[c].trackguid = GPES(key..'trackguid')                    
                    strips[ss][p].controls[c].dvaloffset = GPES(key..'dvaloffset',true)
                    strips[ss][p].controls[c].minov = GPES(key..'minov',true)
                    strips[ss][p].controls[c].maxov = GPES(key..'maxov',true)
                    strips[ss][p].controls[c].membtn = {state = tobool(nz(GPES(key..'memstate',true),false)),
                                                        mem = tonumber(nz(GPES(key..'memmem',true),0))
                                                        }
                    
                    strips[ss][p].controls[c].cycledata.statecnt = tonumber(nz(GPES(key..'cycledata_statecnt',true),0))
                    strips[ss][p].controls[c].cycledata.mapptof = tobool(nz(GPES(key..'cycledata_mapptof',true),false))
                    strips[ss][p].controls[c].cycledata.pos = tonumber(nz(GPES(key..'cycledata_pos',true),1))
                    strips[ss][p].controls[c].cycledata.posdirty = tobool(nz(GPES(key..'cycledata_posdirty',true),false))
                    strips[ss][p].controls[c].cycledata.val = 0
                    if nz(strips[ss][p].controls[c].cycledata.statecnt,0) > 0 then
                      for i = 1, strips[ss][p].controls[c].cycledata.statecnt do
                        local key = 'strips_'..s..'_'..p..'_controls_'..c..'_cycledata_'..i..'_'
                      
                        strips[ss][p].controls[c].cycledata[i] = {val = tonumber(nz(GPES(key..'val',true),0)),
                                                                  dispval = nz(GPES(key..'dispval',true),'no disp val')
                                                                  }                    
                      end
                    end
                                        
                    --load control images - reshuffled to ensure no wasted slots between sessions
                    local iidx
                    local knob_sel = -1
                    for k = 0, #ctl_files do
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
                                                id = deconvnum(GPES(key..'id',true)),
                                                gfxtype = tonumber(nz(GPES(key..'gfxtype',true),gfxtype.img)),
                                                font = {idx = tonumber(GPES(key..'font_idx',true)),
                                                        name = GPES(key..'font_name',true),
                                                        size = tonumber(GPES(key..'font_size',true)),
                                                        bold = tobool(GPES(key..'font_bold',true)),
                                                        italics = tobool(GPES(key..'font_italics',true)),
                                                        underline = tobool(GPES(key..'font_underline',true)),
                                                        shadow = tobool(nz(GPES(key..'font_shadow',true),true)),
                                                        shadow_x = tonumber(nz(GPES(key..'font_shadowx',true),1)),
                                                        shadow_y = tonumber(nz(GPES(key..'font_shadowy',true),1)),
                                                        shadow_a = tonumber(nz(GPES(key..'font_shadowa',true),0.6))
                                                        },
                                                text = GPES(key..'text',true),
                                                text_col = GPES(key..'text_col',true),
                                                poslock = tobool(nz(GPES(key..'poslock',true),false))
                                               }
                    strips[ss][p].graphics[g].stretchw = tonumber(nz(GPES(key..'stretchw',true),strips[ss][p].graphics[g].w))
                    strips[ss][p].graphics[g].stretchh = tonumber(nz(GPES(key..'stretchh',true),strips[ss][p].graphics[g].h))

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
        
        local scnt = tonumber(nz(GPES('snapshots_count'),0))
        if scnt and scnt > 0 then
          snapshots = {}
            
          for s = 1, scnt do

            snapshots[s] = {}
          
            for p = 1, 4 do
            
              snapshots[s][p] = {}

              local key = 'snap_strip_'..s..'_'..p..'_'
              local sstcnt = tonumber(nz(GPES(key..'sstype_count',true),0))
              
              if sstcnt > 0 then
                
                for sst = 1, sstcnt do
                
                  snapshots[s][p][sst] = {}
                
                  local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_'
                  local sscnt = tonumber(nz(GPES(key..'ss_count',true),0))
                  
                  if sscnt > 0 then
              
                    for ss = 1, sscnt do
                      local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_snapshot_'..ss..'_'
                      local dcnt = tonumber(GPES(key..'data_count'))
                      snapshots[s][p][sst][ss] = {name = GPES(key..'name'),
                                                  data = {}}
                      for d = 1, dcnt do
    
                        local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_snapshot_'..ss..'_data_'..d..'_'
                      
                        snapshots[s][p][sst][ss].data[d] = {c_id = tonumber(GPES(key..'cid')),
                                                           ctl = tonumber(GPES(key..'ctl')),
                                                           val = tonumber(GPES(key..'val')),
                                                           dval = tonumber(GPES(key..'dval'))}
                      end
                    end
                    
                    Snapshots_Check(s,p)          
                  end
                end
              end
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
    if tracks and tracks[track_select] and tracks[track_select].strip and strips[tracks[track_select].strip] then
    --if tracks[track_select].strip and strips[tracks[track_select].strip] then
      surface_offset.x = tonumber(strips[tracks[track_select].strip][page].surface_x)
      surface_offset.y = tonumber(strips[tracks[track_select].strip][page].surface_y)
    end    
    --[[local ww = gfx1.main_w-(plist_w+2)
    if surface_size.w < ww then
      surface_offset.x = -math.floor((ww - surface_size.w)/2)
    end]]
    
  end
  
  function LoadSettings()
    settings_saveallfxinststrip = tobool(nz(GES('saveallfxinststrip',true),settings_saveallfxinststrip))
    settings_followselectedtrack = tobool(nz(GES('followselectedtrack',true),settings_followselectedtrack))
    settings_disablesendchecks = tobool(nz(GES('disablesendchecks',false),settings_disablesendchecks))
    settings_updatefreq = tonumber(nz(GES('updatefreq',true),settings_updatefreq))
    settings_mousewheelknob = tobool(nz(GES('mousewheelknob',true),settings_mousewheelknob))
    dockstate = nz(GES('dockstate',true),0)
    lockx = tobool(nz(GES('lockx',true),false))
    locky = tobool(nz(GES('locky',true),false))
    lockw = tonumber(nz(GES('lockw',true),128))
    lockh = tonumber(nz(GES('lockh',true),128))

    
    local sd = tonumber(GES('strip_default',true))
    local sdf = tonumber(GES('stripfol_default',true))
    
    if sd and sdf then
      strip_default = {stripfol_select = sdf, strip_select = sd}
    end
    
  end
  
  function SaveSettings()
    reaper.SetExtState(SCRIPT,'saveallfxinststrip',tostring(settings_saveallfxinststrip), true)
    reaper.SetExtState(SCRIPT,'followselectedtrack',tostring(settings_followselectedtrack), true)
    reaper.SetExtState(SCRIPT,'disablesendchecks',tostring(settings_disablesendchecks), true)
    reaper.SetExtState(SCRIPT,'updatefreq',settings_updatefreq, true)
    reaper.SetExtState(SCRIPT,'mousewheelknob',tostring(settings_mousewheelknob), true)
    local d = gfx.dock(-1)
    reaper.SetExtState(SCRIPT,'dockstate',d, true)
    reaper.SetExtState(SCRIPT,'lockx',tostring(lockx), true)
    reaper.SetExtState(SCRIPT,'locky',tostring(locky), true)
    reaper.SetExtState(SCRIPT,'lockw',tostring(lockw), true)
    reaper.SetExtState(SCRIPT,'lockh',tostring(lockh), true)
    
    if strip_default then
      reaper.SetExtState(SCRIPT,'strip_default',tostring(strip_default.strip_select), true)
      reaper.SetExtState(SCRIPT,'stripfol_default',tostring(strip_default.stripfol_select), true)
    end
    
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
    reaper.SetProjExtState(0,SCRIPT,'locksurface',tostring(settings_locksurface))
    
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
                reaper.SetProjExtState(0,SCRIPT,key..'cid',strips[s][p].controls[c].c_id)
                reaper.SetProjExtState(0,SCRIPT,key..'fxname',strips[s][p].controls[c].fxname)
                reaper.SetProjExtState(0,SCRIPT,key..'fxguid',nz(strips[s][p].controls[c].fxguid,''))
                reaper.SetProjExtState(0,SCRIPT,key..'fxnum',nz(strips[s][p].controls[c].fxnum,''))
                reaper.SetProjExtState(0,SCRIPT,key..'fxfound',tostring(strips[s][p].controls[c].fxfound))
                reaper.SetProjExtState(0,SCRIPT,key..'param',strips[s][p].controls[c].param)
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_name',strips[s][p].controls[c].param_info.paramname)
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_paramnum',strips[s][p].controls[c].param_info.paramnum)
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_idx',nz(strips[s][p].controls[c].param_info.paramidx,''))
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_str',nz(strips[s][p].controls[c].param_info.paramstr,''))
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_guid',nz(strips[s][p].controls[c].param_info.paramdestguid,''))
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_chan',nz(strips[s][p].controls[c].param_info.paramdestchan,''))
                reaper.SetProjExtState(0,SCRIPT,key..'param_info_srcchan',nz(strips[s][p].controls[c].param_info.paramsrcchan,''))
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
                reaper.SetProjExtState(0,SCRIPT,key..'dvaloffset',nz(strips[s][p].controls[c].dvaloffset,''))   
                reaper.SetProjExtState(0,SCRIPT,key..'minov',nz(strips[s][p].controls[c].minov,''))   
                reaper.SetProjExtState(0,SCRIPT,key..'maxov',nz(strips[s][p].controls[c].maxov,''))   
                reaper.SetProjExtState(0,SCRIPT,key..'scalemodex',nz(strips[s][p].controls[c].scalemode,8))   
                reaper.SetProjExtState(0,SCRIPT,key..'framemodex',nz(strips[s][p].controls[c].framemode,1))   
                reaper.SetProjExtState(0,SCRIPT,key..'poslock',nz(tostring(strips[s][p].controls[c].poslock),false))   
                           
                reaper.SetProjExtState(0,SCRIPT,key..'id',convnum(strips[s][p].controls[c].id))

                reaper.SetProjExtState(0,SCRIPT,key..'ctlcat',nz(strips[s][p].controls[c].ctlcat,''))
                reaper.SetProjExtState(0,SCRIPT,key..'tracknum',nz(strips[s][p].controls[c].tracknum,''))
                reaper.SetProjExtState(0,SCRIPT,key..'trackguid',nz(strips[s][p].controls[c].trackguid,''))
                reaper.SetProjExtState(0,SCRIPT,key..'memstate',tostring(nz(strips[s][p].controls[c].membtn.state,false)))
                reaper.SetProjExtState(0,SCRIPT,key..'memmem',nz(strips[s][p].controls[c].membtn.mem,0))
                if strips[s][p].controls[c].cycledata and strips[s][p].controls[c].cycledata.statecnt then
                  reaper.SetProjExtState(0,SCRIPT,key..'cycledata_statecnt',nz(strips[s][p].controls[c].cycledata.statecnt,0))
                  reaper.SetProjExtState(0,SCRIPT,key..'cycledata_mapptof',tostring(nz(strips[s][p].controls[c].cycledata.mapptof,false)))
                  reaper.SetProjExtState(0,SCRIPT,key..'cycledata_pos',tostring(nz(strips[s][p].controls[c].cycledata.pos,1)))
                  reaper.SetProjExtState(0,SCRIPT,key..'cycledata_posdirty',tostring(nz(strips[s][p].controls[c].cycledata.posdirty,false)))
                  if nz(strips[s][p].controls[c].cycledata.statecnt,0) > 0 then
                    for i = 1, strips[s][p].controls[c].cycledata.statecnt do
                      local key = 'strips_'..s..'_'..p..'_controls_'..c..'_cycledata_'..i..'_'
                      reaper.SetProjExtState(0,SCRIPT,key..'val',nz(strips[s][p].controls[c].cycledata[i].val,0))   
                      reaper.SetProjExtState(0,SCRIPT,key..'dispval',nz(strips[s][p].controls[c].cycledata[i].dispval,''))   
                    end
                  end
                else
                  reaper.SetProjExtState(0,SCRIPT,key..'cycledata_statecnt',0)                   
                end     
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
                reaper.SetProjExtState(0,SCRIPT,key..'stretchw',nz(strips[s][p].graphics[g].stretchw,strips[s][p].graphics[g].w))
                reaper.SetProjExtState(0,SCRIPT,key..'stretchh',nz(strips[s][p].graphics[g].stretchh,strips[s][p].graphics[g].h))
                reaper.SetProjExtState(0,SCRIPT,key..'scale',strips[s][p].graphics[g].scale)
                reaper.SetProjExtState(0,SCRIPT,key..'id',convnum(strips[s][p].graphics[g].id))
              
                reaper.SetProjExtState(0,SCRIPT,key..'gfxtype',nz(strips[s][p].graphics[g].gfxtype, gfxtype.img))
                reaper.SetProjExtState(0,SCRIPT,key..'font_idx',nz(strips[s][p].graphics[g].font.idx, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_name',nz(strips[s][p].graphics[g].font.name, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_size',nz(strips[s][p].graphics[g].font.size, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_bold',nz(tostring(strips[s][p].graphics[g].font.bold), ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_italics',nz(tostring(strips[s][p].graphics[g].font.italics), ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_underline',nz(tostring(strips[s][p].graphics[g].font.underline), ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_shadow',nz(tostring(strips[s][p].graphics[g].font.shadow), ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_shadowx',nz(strips[s][p].graphics[g].font.shadow_x, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_shadowy',nz(strips[s][p].graphics[g].font.shadow_y, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'font_shadowa',nz(strips[s][p].graphics[g].font.shadow_a, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'text',nz(strips[s][p].graphics[g].text, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'text_col',nz(strips[s][p].graphics[g].text_col, ''))
                reaper.SetProjExtState(0,SCRIPT,key..'poslock',nz(tostring(strips[s][p].graphics[g].poslock), false))
              
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
  
    --DBG(#snapshots)
    if snapshots and #snapshots > 0 then
      reaper.SetProjExtState(0,SCRIPT,'snapshots_count',#snapshots)
    
      for s = 1, #snapshots do
        for p = 1, #snapshots[s] do

          local key = 'snap_strip_'..s..'_'..p..'_'          
          reaper.SetProjExtState(0,SCRIPT,key..'sstype_count',#snapshots[s][p])
        
          for sst = 1, #snapshots[s][p] do
        
            local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_'          
            reaper.SetProjExtState(0,SCRIPT,key..'ss_count',#snapshots[s][p][sst])
          
            if #snapshots[s][p][sst] > 0 then
  
              for ss = 1, #snapshots[s][p][sst] do
  
                local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_snapshot_'..ss..'_'
              
                reaper.SetProjExtState(0,SCRIPT,key..'name',snapshots[s][p][sst][ss].name)
                reaper.SetProjExtState(0,SCRIPT,key..'data_count',#snapshots[s][p][sst][ss].data)
            
                if #snapshots[s][p][sst][ss].data > 0 then
                  for d = 1, #snapshots[s][p][sst][ss].data do
    
                    local key = 'snap_strip_'..s..'_'..p..'_type_'..sst..'_snapshot_'..ss..'_data_'..d..'_'
              
                    reaper.SetProjExtState(0,SCRIPT,key..'cid',snapshots[s][p][sst][ss].data[d].c_id)                
                    reaper.SetProjExtState(0,SCRIPT,key..'ctl',snapshots[s][p][sst][ss].data[d].ctl)                
                    reaper.SetProjExtState(0,SCRIPT,key..'val',snapshots[s][p][sst][ss].data[d].val)
                    reaper.SetProjExtState(0,SCRIPT,key..'dval',snapshots[s][p][sst][ss].data[d].dval)
              
                  end
                end
              end
            end      
          end
        end
      end
    
    else
      reaper.SetProjExtState(0,SCRIPT,'snapshots_count',0)        
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

  function Snapshots_Check(strip, page)
  
    if snapshots and snapshots[strip] then
      if #snapshots[strip][page] > 0 then    
    
        for sst = 1, #snapshots[strip][page] do
        
          if #snapshots[strip][page][sst] > 0 then
        
            for ss = 1, #snapshots[strip][page][sst] do
              local ss_entry_deleted = false
              local dcnt = #snapshots[strip][page][sst][ss].data    
              if dcnt > 0 then
                local notfoundcnt = 0
                for d = 1, dcnt do
                
                  if strips[strip][page].controls[snapshots[strip][page][sst][ss].data[d].ctl] == nil or
                     snapshots[strip][page][sst][ss].data[d].c_id ~= strips[strip][page].controls[snapshots[strip][page][sst][ss].data[d].ctl].c_id then
                    --control numbers not match - a control has been deleted
                      local found = false
                      for c = snapshots[strip][page][sst][ss].data[d].ctl-notfoundcnt, #strips[strip][page].controls do
                        if strips[strip][page].controls[c] then
                          if snapshots[strip][page][sst][ss].data[d].c_id == strips[strip][page].controls[c].c_id then
                            found = true
                            snapshots[strip][page][sst][ss].data[d].ctl = c
                            break
                          end
                        end
                      end
                      if found == false then
                        --snapshot entry not found
                        notfoundcnt = notfoundcnt + 1
                        snapshots[strip][page][sst][ss].data[d] = nil
                        ss_entry_deleted = true
                      end
                  end
                end
                
                if ss_entry_deleted == true then
                  snapshots[strip][page][sst][ss].data = Table_RemoveNils(snapshots[strip][page][sst][ss].data, dcnt)
                end
              end
            end
          end
        end
      end
    end  
  
  end

  ------------------------------------------------------------

  function Table_RemoveNils(srctbl, dcnt)
  
    local tbl = {}
    
    if dcnt > 0 then
      for i = 1, dcnt do
        if srctbl[i] ~= nil then
          table.insert(tbl, srctbl[i])
        end
      end
    end
    return tbl
      
  end
  
  ------------------------------------------------------------

  function Snapshot_Set(strip, page)
  
    if snapshots[strip][page][sstype_select][ss_select] then
      for ss = 1, #snapshots[strip][page][sstype_select][ss_select].data do
        local c = snapshots[strip][page][sstype_select][ss_select].data[ss].ctl
        local v = snapshots[strip][page][sstype_select][ss_select].data[ss].dval
        if c and v then
          trackfxparam_select = c
          local trnum = nz(strips[strip][page].controls[c].tracknum,strips[strip].track.tracknum)
          SetParam3_Denorm(trnum, v)        
        end
      end
    end    
  end
  
  function Snapshots_CREATE(strip, page, sstype, ss_ovr)

    if strips and strips[strip] and strips[strip][page] and #strips[strip][page].controls > 0 then

      if snapshots == nil then
        snapshots = {}
      end
      for s = 1, reaper.CountTracks(0)+1 do
        if snapshots[s] == nil then
          snapshots[s] = {}
          for p = 1, 4 do
            snapshots[s][p] = {}
          end
        end
      end
      if snapshots[strip][page] == nil then
        snapshots[strip][page] = {}
      end
      if snapshots[strip][page][sstype] == nil then
        snapshots[strip][page][sstype] = {}
      end
      if ss_ovr then
        snappos = ss_ovr
        if snapshots[strip][page][sstype][snappos] then
          snapshots[strip][page][sstype][snappos].data = {}
        else
          return false
        end
      else
        snappos = #snapshots[strip][page][sstype] + 1
        snapshots[strip][page][sstype][snappos] = {name = 'Snapshot '..snappos,
                                                   data = {}} 
      end
      
      local sscnt = 1
      for c = 1, #strips[strip][page].controls do
      
        if strips[strip][page].controls[c].ctlcat == ctlcats.fxparam or
           strips[strip][page].controls[c].ctlcat == ctlcats.trackparam or
           strips[strip][page].controls[c].ctlcat == ctlcats.tracksend then
          if strips[strip][page].controls[c].ctltype ~= 5 then
            local track = GetTrack(nz(strips[strip][page].controls[c].tracknum,strips[strip].track.tracknum))
            local cc = strips[strip][page].controls[c].ctlcat
            local fxnum = strips[strip][page].controls[c].fxnum
            local param = strips[strip][page].controls[c].param
            local min, max = GetParamMinMax(cc,track,nz(fxnum,-1),param,true,c)
            local dval = DenormalizeValue(min,max,strips[strip][page].controls[c].val)
            snapshots[strip][page][sstype][snappos].data[sscnt] = {c_id = strips[strip][page].controls[c].c_id,
                                                                    ctl = c,
                                                                    val = strips[strip][page].controls[c].val,
                                                                    dval = dval}
            sscnt = sscnt + 1
          end
        end
      end
    end
    
  end
  
  ------------------------------------------------------------
  
  function EnableLatch(c)
  
    if strips[tracks[track_select].strip][page].controls[c].ctlcat == ctlcats.fxparam then
      local trn = nz(strips[tracks[track_select].strip][page].controls[c].tracknum, strips[tracks[track_select].strip].track.tracknum)
      local track = GetTrack(trn)
      local env = reaper.GetFXEnvelope(track,strips[tracks[track_select].strip][page].controls[c].fxnum,strips[tracks[track_select].strip][page].controls[c].param, false)
      if env then
        local retval, envchunk = reaper.GetEnvelopeStateChunk(env,'',true)
        --DBG(retval)
        --DBG(envchunk)
        local s, e = string.find(envchunk,'ACT 1')
        if s and e then
          nchunk = string.sub(envchunk,1,s-1) .. 'ACT 0' .. string.sub(envchunk,e+1)
          reaper.SetEnvelopeStateChunk(env, nchunk, true)
        end
      end
    end
    
  end
    
  ------------------------------------------------------------
    
  function INIT()

    PROJECTID = math.ceil((math.abs(math.sin( -1 + (os.clock() % 2)))) * 0xFFFFFFFF)
    
    mode = 0
    submode = 2
    fxmode = 0
    butt_h = 20
    fx_h = 160
    snaph = 300
  
    ogrid = settings_gridsize
    sb_size = 3
    
    P_butt_cnt = 0
    F_butt_cnt = 0
    G_butt_cnt = 0
    S_butt_cnt = 0
    SF_butt_cnt = 0
    tlist_offset = 0
    sflist_offset = 0
    cyclist_offset = 0
    trctltypelist_offset = 0
    trctlslist_offset = 0
    ssoffset = 0
    
    strips = {}
    surface_offset = {x = 0, y = 0}
    
    max_cycle = 64
    
    image_count = 1
    knob_select = 0
    ksel_size = 50
    ksel_loaded = false
    page = 1
    
    gfx_select = 0
    track_select = 0
    trackedit_select = 0
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
    cycle_select = {statecnt = 0,val = 0,mapptof = false,nil}
    minov_select = nil
    maxov_select = nil
    dvaloff_select = 0
    trctltype_select = 0
    trctl_select = 1
    gfx_font_select = {idx = 1,
                         name = fontname_def,
                         size = fontsize_def,
                         bold = false,
                         italic = false,
                         underline = false,
                         shadow = true,
                         shadow_x = 1,
                         shadow_y = 1,
                         shadow_a = 0.6}
    gfx_textcol_select = '255 255 255'
    gfx_text_select = ''
    knob_scalemode_select = 1
    scalemode_select = 8
    framemode_select = 1
    sstype_select = 1
    
    plist_w = 140
    oplist_w = 140
    
    time_nextupdate = 0
    time_checksend = 0
    time_sendupdate = 0
    
    show_ctloptions = false
    show_lbloptions = false
    show_editbar = true
    show_settings = false
    show_cycleoptions = false
    show_paramlearn = false
    show_snapshots = false
    
    show_paramname = true
    show_paramval = true
    
    ctl_page = 0
    cycle_editmode = false
    
    last_gfx_w = 0
    last_gfx_h = 0
    
    octlval = -1
    otrkcnt = -1
    ofxcnt = -1
    checktr = 0    
  
    PopulateTracks()
    PopulateGFX()
    PopulateControls()
    PopulateStripFolders()
    PopulateStrips()
    PopulateMediaItemInfo()
    PopulateTrackSendsInfo()
    
    EB_Open = 0
    EB_Enter = false
    
    MS_Open = 0
    MB_Enter = false
    
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
  
  function frameScale(m, v)
    
    if m == 1 then
      return v
    elseif m == 2 then
      return outCirc(v)
    else
      return v
    end
  
  end
  
  function ctlScale(m, v)
  
    local mm = scalemode_table[m]
    return v^mm
  
  end

  function ctlScaleInv(m, v)
  
    local mm = 1/scalemode_table[m]
    return v^mm
  
  end
  
  function inQuint(t)
    return t^5
  end

  function inQuintInv(v)
    return v^0.2
  end
  
  function quit()
  
    --local res = reaper.MB('Save data and project?', 'Save data',4) 
    --if res == 1 then  
      SaveData()
      SaveSettings()
    --end
    gfx.quit()
    
  end
  
  ------------------------------------------------------------

  SCRIPT = 'LBX_STRIPPER'
  VERSION = 0.91

  OS = reaper.GetOS()
  
  math.randomseed(os.clock())
  
  lockx = false
  locky = false
  lockw, olockw = 0, 0
  lockh, olockh = 0, 0

  resource_path = reaper.GetResourcePath().."/Scripts/LBX/LBXCS_resources/"
  controls_path = resource_path.."controls/"
  graphics_path = resource_path.."graphics/"
  icon_path = resource_path.."icons/"
  strips_path = resource_path.."strips/"

  settings_followselectedtrack = true
  settings_autocentrectls = false
  settings_disablesendchecks = false
  settings_gridsize = 16
  settings_showgrid = true
  osg = settings_showgrid
  settings_saveallfxinststrip = false
  settings_updatefreq = 0.05
  settings_showbars = true
  settings_mousewheelknob = false
  settings_locksurface = false
  settings_ExtendedAPI = reaper.APIExists('BR_GetMediaTrackSendInfo_Track')
  
  dockstate = 0
  
  fontname_def = 'Calibri'
  fontsize_def  = 18
  
  surface_size = {w = 2048, h = 2048, limit = true}
  
  gfx.loadimg(0,controls_path.."__default.png") -- default control
  --gfx.loadimg(1010,controls_path.."__default.png")
  
  --def_knob = 0  
  gfx.loadimg(1021,icon_path.."bin.png")
  
  defctls = {}
  
  --gfx.loadimg(1020,controls_path.."missing.png") --update to missing png
  def_knob = LoadControl(1019, '__default.knb')
  def_knobsm = LoadControl(1018, 'SimpleFlat_48.knb')
  
  INIT()
  LoadSettings()
  LoadData()  
  Lokasenna_Window_At_Center(gfx1.main_w,gfx1.main_h) 
--test jsfx plug name in quotes
--DBG(GetPlugNameFromChunk('JS \"AB Level Matching JSFX [2.5]/AB_LMLT_cntrl\" \"MSTR /B\"\10.000000 0.000000 300.000000 0.000000 - - - - - 0.000000 - - - - - - - - - -14.600000 -11.600000 -7.000000 7.000000 -4.800000 - - - - - -14.500000 -11.800000 -4.100000 10.000000 -4.100000 - - - - - 0.000000 1.000000 0.000000 - 0.000000 0.000000 - - - - 7681.000000 1.000000 - - - - - - - - - - - - - '))

  gfx.dock(dockstate)
  run()
  
  reaper.atexit(quit)
  
