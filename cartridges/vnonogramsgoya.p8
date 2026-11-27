pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--nonograms of goya's paintings
--game by uvehj
debug_select = false
puzzle = {}
menustate = 1
state = 0
cursorpos = {0,0}
checkcounter = 30
currentpuzzle = {1,1}
currentimage = 1
cooldown = 0
menucamera = {objective=-128,position=-128, speed=600}
band = {objective=30,position=30,defaults={30,-75}, speed=600}
images = {}
image_info={
        {name="witches' flight", year = "1798"},
        {name="witches' sabbath", year = "1798"},
        {name="portrait of antonia zarate", year = "1810/1811"},
        {name="saturn devouring his son", year = "1820/1823"}
    }
last_beaten = {0,0,0,0}
puzzles_per_image = {0,0,0,0}
function _init()
    images[1] = load_all_puzzles(get_level1())
    images[2] = load_all_puzzles(get_level2())
    images[3] = load_all_puzzles(get_level3())
    images[4] = load_all_puzzles(get_level4())
    state = 0
    cartdata("uvehjvnonogramsgoya")
    local i = 1
    while i <= #images do
        last_beaten[i] = dget(i)
        i += 1
    end
    menuitem(1, "back to menu", back_to_menu)
    menuitem(2, " ", nothing )
    menuitem(3, "delete progress", delete_progress)
    menuitem(4, " ", nothing )
end

function nothing()
end

function back_to_menu()
    band.objective= band.defaults[menustate]
    state = 0
end

function delete_progress()
    local i = 1
    last_beaten = {0,0,0,0}
    while i <= #images do
        dset(i,0)
        i += 1
    end
end

function decode_grid(puzzle_string, width, height)

    local grid = {}

    --full White or black
    if sub(puzzle_string, 1, 1) == "W" or sub(puzzle_string, 1, 1) == "B" then
        local fill = (puzzle_string == "B") and 1 or 0
        local trivial = (sub(puzzle_string, 2, 2) == "n") and 0 or 1
        for y = 1, height do
            local r = {}
            for x = 1, width do add(r, fill) end
            add(grid, r)
        end
        return trivial, grid
    end

    local trivial = (sub(puzzle_string, 1, 1) == "t") and 1 or 0
    local rows = split(sub(puzzle_string, 2), "/", false)

    for row in all(rows) do
        local row_as_decimal = tonum("0x" .. row) --convert hex to decimal
        local decoded_rows = {}
        for x = width - 1, 0, -1 do
            add(decoded_rows, (row_as_decimal >>> x) & 1)
        end
        add(grid, decoded_rows)
    end

    return trivial, grid
end

function load_all_puzzles(puzzle_strings)
    local unpacked = {}
    local total_puzzles = 0

    for row in all(puzzle_strings) do
        local height = row[1]
        local width = row[2]
        local row_list = {}

    -- puzle strings start at 3
        for i = 3, #row do
            local puzzle_string = row[i]
            local trivial, grid = decode_grid(puzzle_string, width, height)
            add(row_list, {
                width = width,
                height = height,
                trivial = trivial,
                grid = grid,
            })
        end

        add(unpacked, row_list)
        total_puzzles += #row_list
    end

    puzzles_per_image[#images+1] = total_puzzles

    return unpacked
end

function draw_all_puzzles(image_id, start_x, draw_selected_puzzle)

    local puzzle_list = images[image_id]
    local current_y = 0

    color(7)
    if(last_beaten[image_id]>=puzzles_per_image[image_id]) color(9)
    line(start_x+3,0,start_x+3,128)
    line(start_x,0,start_x+128,0)
    line(start_x+124,0,start_x+124,128)
    line(start_x,127,start_x+128,127)
    rect(start_x+1, 0, start_x+3, 2)
    rect(start_x+124, 0, start_x+126, 2)
    rect(start_x+1, 125, start_x+3, 127)
    rect(start_x+124, 125, start_x+126, 127)
    
    if(image_id>1) print(chr(22), start_x, 60)
    if(image_id<#images) print(chr(23), start_x+125, 60)
    color()

    selected ={0,0,0,0}
    local puzzle_counter = 0
    rectfill(start_x+4, 0, start_x+123, 128, 5)

    for x=1, #puzzle_list do
        local row = puzzle_list[x]
        local current_x = start_x+4
        local_reached_beaten = false

        for y=1, #row do 
            local puzzle = row[y]
            if(puzzle.trivial == 1) last_beaten[image_id] = max(puzzle_counter + 1, last_beaten[image_id])
            if(draw_selected_puzzle == true and puzzle_counter==last_beaten[image_id] and debug_select==false) then
                currentpuzzle[1] = x
                currentpuzzle[2] = y
            end
            
            if(currentpuzzle[1] == x and currentpuzzle[2] == y)selected = {current_x, current_y, current_x + puzzle.width-1, current_y + puzzle.height-1}
            if(debug_select == false and puzzle_counter==last_beaten[image_id])then
                local_reached_beaten = true
                break
            end
            if (max(current_x, menucamera.position) <= min(current_x+puzzle.width, menucamera.position+128)) then
                for py = 1, puzzle.height do
                    for px = 1, puzzle.width do
                        local pixel = puzzle.grid[py][px]
                        local col = (pixel == 1) and 0 or 7
                        pset(current_x + px - 1, current_y + py - 1, col)
                    end
                end
            end
            current_x += puzzle.width
            puzzle_counter+=1
        end
        if(local_reached_beaten == true) break
        current_y += row[1].height
    end
    if (draw_selected_puzzle==true and selected~={0,0,0,0}) then
        if (last_beaten[image_id]<puzzles_per_image[image_id]) rect(selected[1]-1,selected[2]-1,selected[3]+1,selected[4]+1, 8)
    else
        draw_title_card(image_id, start_x)
    end
end

function draw_title_card(image_id, start_x)
    local start_y = 112
    local length = (#image_info[image_id].name+1) *4 +4
    rectfill(start_x +5, start_y, start_x+length, start_y+14,0)
    color(7)
    if(last_beaten[image_id]>=puzzles_per_image[image_id]) color(9)
    rect(start_x +5, start_y, start_x+length, start_y+14)
    local name_text = "?????"
    if(last_beaten[image_id]>=flr(puzzles_per_image[image_id]*0.8)) name_text = image_info[image_id].name
    print(name_text, start_x +7, start_y+2)
    local year_text = "?????"
    if(last_beaten[image_id]>=flr(puzzles_per_image[image_id]*0.4)) year_text = image_info[image_id].year
    print(year_text, start_x +7, start_y+8)
end

function _draw()
    cls(0)

    if state == 1 then
        draw_band()
        draw_board(puzzle.x,puzzle.y)
        draw_cursor(puzzle.x,puzzle.y)
    elseif state == 2 then
        draw_band()
        draw_board(puzzle.x,puzzle.y)
        draw_win()
    elseif state == 0 then
        draw_title()
    end
 
end

function _update60()
    if(state == 0 and menustate ~=2) then
        menucamera.position = 0
        menucamera.objective = 0
    end
    if state == 1 then
        update_buttons_game()
        cooldown = max(0, cooldown - (1/60))
        checkcounter -= 1
        if checkcounter <= 0 then
            state = check_finished_and_autocomplete()
            checkcounter = 30
        end
    elseif state == 0 then
        update_buttons_menu()
    elseif state == 2 then
        cooldown = max(0, cooldown - (1/60))
        update_buttons_finish()
    end
end

function update_camera()
    menucamera.objective = -256 + (128*currentimage)
    if(menucamera.position<menucamera.objective) then
        menucamera.position = min(menucamera.objective, menucamera.position+(menucamera.speed/60))
    elseif(menucamera.position>menucamera.objective) then
        menucamera.position = max(menucamera.objective, menucamera.position-(menucamera.speed/60))
    end
end

function create_puzzle()
    puzzle_grid = images[currentimage][currentpuzzle[1]][currentpuzzle[2]]
    puzzle.width = puzzle_grid.width
    puzzle.height = puzzle_grid.height
    puzzle.mistakes=0
    puzzle.board = {}
    local x = 0
    local y = 0
    local max_row_numbers = 0
    local max_column_numbers = 0;

    for x = 1, puzzle.width do
        local col = {}
        for y = 1, puzzle.height do
            local tile = puzzle_grid.grid[y][x]
            add(col, {tile, 0, 0})
        end
        add(puzzle.board, col)
    end

    puzzle.rownumbers = {}
    y = 1
    while y <= puzzle.height do
        x = 1
        local curnumber = 0
        local currow = {}
        while x <= puzzle.width do
            if curnumber != 0 and puzzle.board[x][y][1] == 0 then
                add(currow,curnumber)
                curnumber = 0
            end
            if puzzle.board[x][y][1] == 1 then
                curnumber += 1
            end
            x += 1
        end
        if curnumber != 0 then
            add(currow,curnumber)
        end
        max_row_numbers = max(#currow, max_row_numbers)
        add(puzzle.rownumbers,currow)
        y += 1
    end
    puzzle.columnnumbers = {}
    x = 1
    while x <= puzzle.width do
        y = 1
        local curnumber = 0
        local curcolumn = {}
        while y <= puzzle.height do
            if curnumber != 0 and puzzle.board[x][y][1] == 0 then
                add(curcolumn,curnumber)
                curnumber = 0
            end
            if puzzle.board[x][y][1] == 1 then
                curnumber += 1
            end
            y += 1
        end
        if curnumber != 0 then
            add(curcolumn,curnumber)
        end
        max_column_numbers = max(#curcolumn, max_column_numbers)
        add(puzzle.columnnumbers,curcolumn)
        x += 1
    end

    puzzle.x = center_element( (puzzle.width*8)+(max_row_numbers*5),30,127)
    puzzle.y = center_element( (puzzle.height*8)+(max_column_numbers*6),30,127)

    return 1
end

function center_element(element_length, start, ending)
    return start + ((ending - start) - element_length) / 2
end

function draw_title()
    if menustate == 1 then
        camera(0,-10)
        pal(10,0)
        draw_band()
        --"nonograms" letter
        sspr(0,8,8,8,67,32,8*3,8*3,false,false)
        sspr(0,8,8,8,67+8*3,32,8*3,8*3,false,false)
        sspr(8,8,8*3,8,67,50,8*3*3,8*3,false,false)
        --line break
        rectfill(66+8*2*3,32+5,66+8*2*3+8,32+7,7)
        --numbers for the fake nonogram
        local titlerows = {"33","11","21","11","11"," 1"}
        local y = 15
        for row in all(titlerows) do
            print(row,1,y,7)
            y += 8
        end
        print("    1   1\n1 3 2 1 1 5 1",11,1)
        --fake nonogram
        rectfill(9,13,10+7*8,14+6*8,5)
        map(0,0,9,13,7,6)
        rect(9,13,10+7*8,13+6*8,5)
        --rect(9,13,9+7*8,13+6*8,5)
        --gird
        posx = 10
        posy= 14
        for i=0, 7 do
            line(posx+i*8, posy, posx+i*8, posy+6*8-1,5)
            line(posx+i*8-1, posy, posx+i*8-1, posy+6*8-1,5)
        end
        for i=0, 6 do
            line(posx+1, posy+i*8, posx+7*8-2, posy+i*8,5)
            line(posx+1, posy-1+i*8, posx+7*8-2, posy-1+i*8,5)
        end
        --subtitle
        print_subtitle(75,"goya's")
        print_subtitle(83,"dark paintings")

        print("by uvehj",10,112,7)

    elseif (menustate == 2)then 
        camera(menucamera.position,0)
        local image_x = -128
        for i=1, #images do
            if (abs(menucamera.position - image_x) <= 128) then --they overlap
                draw_all_puzzles(i, image_x, false)
            end
            image_x +=128
        end
    elseif (menustate == 3)then
        camera(menucamera.position,0)
        draw_all_puzzles(currentimage, 0, true)
    end
end

function print_subtitle(y, text)
    local x = 64 - #text*4
    rectfill(x,y,x + #text*8,y+8,5)
    local spriten = 0
    for i = 1, #text do
        spr(1+spriten*2,x,y)
        print(text[i],x+3,y+2,(i%2==0) and 7 or 0)
        rect(x,y,x + 8,y+8,5)
        x += 8
        spriten = abs(spriten-1)
        
    end
end

function draw_win()
    print("puzzle finished! mistakes: "..tostr(puzzle.mistakes),1,1,7)
end

function draw_band()
    local y = 140
    for i = 1, 4 do
        for j=0,i*2 do
            line(0,y+j,128,-65+y+j,7)
            i += 1
        end
        y+=i*2
    end
end

function draw_board(posx,posy)
    --board
    rectfill(posx-1,posy-1,posx+puzzle.width*8,posy+puzzle.height*8,5)
    local x = 1
    while x <= puzzle.width do
        local y = 1
        while y <= puzzle.height do
            spr(get_tile_sprite(puzzle.board[x][y]),posx+(x-1)*8,posy+(y-1)*8)
            y += 1
        end
        x += 1
    end
    --row numbers
    local ynum = puzzle.y + 2
    for row in all(puzzle.rownumbers) do
        local xnum = puzzle.x + 1
        if(#row>0) do
            for i=#row, 1, -1 do
                xnum -= 6
                if (row[i] >= 10) xnum -= 4
                print(row[i],xnum,ynum,7)
                i-=1
            end
        end
        ynum += 8
    end
    --column numbers
    local xnum = puzzle.x + 2
    for column in all(puzzle.columnnumbers) do
        local ynum = puzzle.y - 1 - #column * 6
        for number in all(column) do
            local offset = 0
            if (number >= 10) offset -= 2
            print(number,xnum+offset,ynum,7)
            ynum += 6
        end
        xnum += 8
    end
    if (state==1) do
        for i=0, puzzle.width do
            line(posx+i*8, posy, posx+i*8, posy+puzzle.height*8-1,5)
            line(posx+i*8-1, posy, posx+i*8-1, posy+puzzle.height*8-1,5)
        end
        for i=0, puzzle.height do
            line(posx+1, posy+i*8, posx+puzzle.width*8-2, posy+i*8,5)
            line(posx+1, posy-1+i*8, posx+puzzle.width*8-2, posy-1+i*8,5)
            if ( i~=0 and i~=puzzle.height and i % 5 == 0) do 
                line(posx+1, posy+i*8, posx+puzzle.width*8-2, posy+i*8,13)
                line(posx+1, posy-1+i*8, posx+puzzle.width*8-2, posy-1+i*8,13)
            end  
        end
        for i=0, puzzle.width do
            if ( i~=0 and i~=puzzle.width and i % 5 == 0) do 
                line(posx+i*8, posy+1, posx+i*8, posy+puzzle.height*8-2,13)
                line(posx+i*8-1, posy+1, posx+i*8-1, posy+puzzle.height*8-2,13)
            end 
        end
    end
end
function draw_cursor(posx,posy)
    spr(7,posx+cursorpos[1]*8,posy+cursorpos[2]*8)
end

function get_tile_sprite(tile)
    if tile[2] == 1 then --tile is uncovered
        if tile[1] == 1 then --tile was colored
            if tile[3] == 1 then --tile is failed
                return 6
            else --colored not failed
                return 3
            end
        else --tile is not colored
           if tile[3] == 1 then --tile is failed
                if(state == 1) do
                    return 5
                else
                    return 9
                end
            else --not colored not failed
                if(state == 1) do
                    return 2
                else
                    return 8
                end
            end         
        end
    else
        return 1
    end
end

function update_buttons_game()
    if btnp(0) then --left
        cursorpos[1] = max(cursorpos[1]-1,0)
    elseif btnp(1) then --right
        cursorpos[1] = min(cursorpos[1]+1,puzzle.width-1)
    elseif btnp(2) then --up
        cursorpos[2] = max(cursorpos[2]-1,0)
    elseif btnp(3) then --down
        cursorpos[2] = min(cursorpos[2]+1,puzzle.height-1)
    end
    if (btn(4) or btn(5)) and puzzle.board[cursorpos[1]+1][cursorpos[2]+1][2] == 0 and cooldown==0 then
        puzzle.board[cursorpos[1]+1][cursorpos[2]+1][2] = 1
        if puzzle.board[cursorpos[1]+1][cursorpos[2]+1][1] == 1 and btn(5) then
            puzzle.board[cursorpos[1]+1][cursorpos[2]+1][3] = 1
            puzzle.mistakes += 1
            sfx(0)
        elseif puzzle.board[cursorpos[1]+1][cursorpos[2]+1][1] == 0 and btn(4) then
            puzzle.board[cursorpos[1]+1][cursorpos[2]+1][3] = 1
            puzzle.mistakes += 1
            sfx(0)
        else
            sfx(1)
        end
    end
end

function update_buttons_menu()
    if(menustate == 1) then
        if btnp(4) then
            menucamera.position = -128
            menucamera.objective = -128
            currentimage = 1
            menustate = 2
        end
    elseif(menustate == 2) then
        update_camera()
        if btnp(4) then
            menustate = 3
            currentpuzzle = {1,1}
        elseif btnp(5) then
            menustate = 1
        elseif btnp(0) then --left
            currentimage = max(1, currentimage-1)
        elseif btnp(1) then --right
            currentimage = min(#images, currentimage+1)
        end
    elseif(menustate == 3) then
        if btnp(5) then
            menustate = 2
            menucamera.position = -258 + (128*currentimage)
        elseif btnp(4) and (last_beaten[currentimage]<puzzles_per_image[currentimage]) then
            sfx(2)
            cooldown = 0.5
            cursorpos = {0,0}
            state = create_puzzle()
        elseif debug_select == true then
            if btnp(2) and currentpuzzle[1] > 1 then
                currentpuzzle[1] -= 1
                sfx(2)
            elseif btnp(1) then
                currentpuzzle[2] += 1
                sfx(2)
            elseif btnp(0) and currentpuzzle[2] > 1 then
                currentpuzzle[2] -= 1
                sfx(2)
            elseif btnp(3) then
                currentpuzzle[1] += 1
                sfx(2)
            end
        end
    end
end

function update_buttons_finish()
    if (btnp(4) or btnp(5)) and cooldown==0 then
        sfx(2)
        state = 0
        band.objective= band.defaults[menustate]
    end
end

function check_finished_and_autocomplete()
    local x = 1
    local y = 1
    local finished = true
    while x <= puzzle.width do
        y = 1
        local finishedcolumn = true
        while y <= puzzle.height do
            if puzzle.board[x][y][1] == 1 and puzzle.board[x][y][2] == 0 then --tile is colored but not revealed
                finished = false
                finishedcolumn = false
            end
            y += 1
        end
        if finishedcolumn == true then
            y = 1
            while y <= puzzle.height do
                puzzle.board[x][y][2] = 1
                puzzle.columnnumbers[x] = {}
                y += 1
            end
        end
        x += 1
    end
    x = 1
    y = 1
    while y <= puzzle.height do
        local x = 1
        local finishedrow = true
        while x <= puzzle.width do
            if puzzle.board[x][y][1] == 1 and puzzle.board[x][y][2] == 0 then --tile is colored but not revealed
                finished = false
                finishedrow = false
            end
            x += 1
        end
        if finishedrow == true then
            x = 1
            while x <= puzzle.width do
                puzzle.board[x][y][2] = 1
                puzzle.rownumbers[y] = {}
                x += 1
            end
        end
        y += 1
    end
    if finished == true then
        sfx(3)
        last_beaten[currentimage] +=1
        dset(currentimage,last_beaten[currentimage])
        cooldown = 1
        return 2
    else
        return 1
    end
end

function get_level1()
    return {
        {8,6,"B","B","B","B","B","B","B","B","B","B","n3f/3f/3f/1f/f/2f/2f/3f","n3f/3b/3f/3f/3f/3b/3d/1f","n3f/3f/3f/3f/3f/3f/f/2f","B","B","B","B","B","B","B"},
        {6,10,"B","B","B","B","B","n3ff/3ff/3ff/3fe/3fe/3fc","n2e7/1af/3ff/3db/3ee/3df","n3bf/3ff/3ff/3ff/37f/ff","B","B","B","B"},
        {9,8,"B","B","B","B","B","B","nff/ff/ff/ff/fe/fe/fd/fc/f8","ndf/9b/1e/77/bf/bf/5f/9f/bf","ndf/ff/cf/ff/a7/3f/ff/bb/e4","nff/bf/7f/ff/ff/ef/ff/df/ff","B","B","B","B","B"},
        {7,10,"B","B","B","B","B","n393/365/387/207/307/20f/f","n3ff/3ef/3ef/3cd/3cf/3cb/18f","n21f/24f/30f/25f/2c7/297/2b7","B","B","B","B"},
        {6,5,"B","B","B","B","B","B","B","B","B","n1f/1e/1f/1c/1c/18","n0/13/2/12/2/5","n1f/d/1f/1f/1f/1d","n1c/1c/18/10/10/10","n1f/1f/1f/1f/1d/1f","n8/1a/15/a/11/11","n7/f/f/f/7/17","B","B","B","B","B","B","B","B"},
        {5,10,"B","n3f8/3f9/3f8/3f9/3fc","n3ff/ff/1ff/3ff/3ff","B","n3f0/3e5/3e0/3de/3f9","n1bf/3f/37e/21e/b4","n9e/9e/21f/be/1f","n3c3/393/375/3c1/3e3","B","B","B","B"},
        {8,5,"B","B","B","t1e/1f/1f/1f/1f/1f/1f/1f","nf/f/15/11/19/18/1b/1f","n1f/1f/1e/0/0/0/1f/1f","n1f/1c/0/0/0/0/0/1c","n1f/0/0/0/0/0/0/f","n1c/0/0/0/0/1/1b/1f","n0/0/0/9/0/1e/17/17","n2/3/15/11/7/7/3/1f","n18/a/18/18/10/10/0/8","n0/4/5/0/11/11/13/3","B","n1e/18/1a/18/1e/1a/18/1c","n11/10/13/12/10/3/8/0","n1f/f/1f/1f/a/1f/d/3","B","t1f/1f/1f/1f/1f/1f/1f/10","t1f/1f/1f/1f/1f/1f/1f/7","B","B","B","B"},
        {6,6,"B","B","B","B","n3e/38/30/20/20/20","n1f/6/0/4/b/4","n27/5/3/1/0/0","n3f/3f/25/1f/35/3f","n37/22/36/3f/33/35","n0/0/31/0/10/0","n27/1f/3f/f/f/f","B","n28/30/31/3c/3e/20","n31/31/21/1/7/27","n3e/3e/3c/3c/3c/38","W","n7/7/f/7/f/17","B","B","B"},
        {7,6,"B","B","B","B","n20/30/38/38/3c/3c/3e","n2/0/1/3/3/0/0","n0/0/0/0/0/24/c","nf/f/0/0/0/0/0","n3d/3b/0/0/0/0/0","n0/0/0/0/1/1/0","n1f/3d/3f/1f/3e/24/34","n3c/3c/30/0/0/0/0","n0/0/0/0/1/0/0","n7/0/0/0/0/0/0","n30/20/0/4/1/1b/0","ne/e/1f/1f/f/0/0","nf/7/7/3/1/0/0","n3f/3f/3f/3f/10/0/0","n3f/3f/3f/3f/0/0/0","n3f/3f/3f/3f/3f/3f/1d"},
        {6,5,"n18/1b/1b/1d/1c/1f","n1f/4/1c/13/1c/1d","n1f/7/0/0/0/1f","n1f/1f/0/0/0/1b","n1f/10/0/0/0/9","n1e/0/0/0/0/10","n0/0/0/0/0/1d","na/f/e/f/1e/1f","n10/18/18/18/18/18","W","W","W","n18/12/0/4/a/0","n0/0/4/d/f/1f","t0/0/0/0/10/10","W","n0/c/c/c/1c/1f","t0/1/1/0/0/1","n0/a/b/2/13/17","n0/10/1f/1f/1f/1f","n0/1/1f/1f/1f/1f","n0/1f/1f/1f/1f/1f","n18/1e/1f/1f/1f/1f","nf/f/7/17/1f/1d"},
        {6,5,"B","B","B","B","n1a/1f/1f/1e/1e/1e","n1a/1c/10/4/4/0","t10/0/0/1/0/4","n1e/7/3/a/6/0","n18/10/10/0/0/0","W","n0/0/0/7/d/16","n0/0/18/1a/5/7","n3/3/1/b/17/b","t1b/1b/1f/1f/1f/1f","n18/10/10/1c/1b/1b","n0/1/0/1/f/1b","t1f/1f/1d/1f/1b/1e","n7/19/1f/1f/1f/1f","t1f/1f/1f/1f/1b/1f","n1f/18/1c/1f/1e/1f","n1f/0/0/0/12/13","n11/0/7/7/7/17","B","B"},
        {5,6,"B","B","B","n3f/3e/3d/3d/3d","n0/20/20/30/20","t10/0/1/2/0","t8/10/4/0/0","t0/0/0/0/3","n7/7/17/3f/3f","n1c/3e/3f/1c/38","n36/24/30/0/1","n1f/1f/f/f/3f","n1f/3f/3f/2f/4","n39/1d/35/27/17","t3f/3f/2b/37/3f","t3f/3f/3f/3d/3f","t3f/3f/3f/3f/3d","t1d/1f/3f/3f/3f","B","B"},
        {9,6,"B","B","B","n3f/2f/3d/33/2f/37/3f/3e/3e","t20/20/0/2/0/4/0/0/0","W","t2/0/1/0/0/0/0/0/0","n1f/19/1a/3e/2e/3e/2e/2c/3f","n3f/1c/18/c/f/1f/3f/3f/3f","n20/0/0/f/3f/3f/3f/3f/3f","n7/f/1f/3f/3f/3f/3f/3f/3f","n3e/3e/3f/3d/3d/39/34/35/3f","n7/1/27/33/1f/f/3f/3e/3e","nf/f/2f/3f/3f/3f/f/3f/3f","B","B","t3f/3f/3f/3f/3f/3f/3d/3f/3f","B","B","B"},
        {5,6,"B","B","B","n3e/3e/3e/1e/3c","t0/22/0/0/8","W","n2/1e/d/d/d","t39/3d/3f/3f/3f","t2f/3f/3f/3f/3f","B","t3f/3f/3f/3f/3e","n3d/2f/27/7/7","n39/38/39/3d/3d","t3f/1e/1f/3f/3f","t3f/3f/f/1f/3f","n3f/30/30/20/20","n3f/27/f/1f/3f","B","B","B"},
        {5,8,"B","B","ne5/f6/fc/fb/ed","n80/0/b0/30/0","nb/2b/39/d/1d","t7f/ff/ff/ff/e7","tff/ff/ff/fe/ff","nff/fe/e8/8/4","n7/7/f/2f/6f","tff/ff/ff/fe/ff","nff/ff/eb/fb/b3","nd1/e3/a3/f3/e1","B","B","B"},
        {8,6,"B","B","B","n3e/3f/3e/3f/3b/38/38/30","n24/1f/3d/3c/3e/3c/34/10","n0/3/20/0/3/7/5/1","n2f/37/1b/3f/b/3f/2f/3f","t3f/3f/3f/3f/3d/3b/3f/3f","t3f/3f/3f/3f/3f/3f/1f/1f","t3e/3f/3f/3f/3f/3f/3f/3f","n24/3e/3f/3f/3f/3f/3f/3f","tf/3f/3f/3f/3f/3f/3f/3f","B","n37/3b/3d/39/3b/3f/3f/3f","t3f/3f/3d/3f/3f/3f/3f/3f","t3b/37/3f/3f/3f/3f/3f/3f","B","B","B","B"},
        {7,8,"B","B","nf1/e0/e1/e0/e0/e0/c0","n4/82/7/3/7/7/f","tfd/ff/ff/ff/ff/ff/ff","tff/ff/fe/fe/fe/ff/ff","t3f/ff/ff/ff/7f/ff/ff","B","B","B","nef/ef/e7/e3/e3/e7/c7","B","B","B","B"},
        {6,5,"B","B","B","n1c/1c/18/18/11/10","n0/0/10/10/0/3","n7/7/f/1f/1f/1f","B","B","B","B","B","B","B","B","B","t1f/1f/1f/1f/1e/1e","n19/11/13/7/d/1f","B","B","B","B","B","B","B"},
        {9,5,"B","B","n1f/1f/1c/1c/1c/1e/1e/1f/1e","n10/3/0/0/0/0/0/10/10","n5/3/7/f/f/f/1f/1f/1f","B","B","B","B","B","B","B","B","B","B","t1d/1f/1f/1f/1f/1f/1f/1f/1f","B","B","B","B","B","B","B","B"},
    }

end

function get_level2()
    return {
        {6,8,"tff/ff/f9/ff/ff/ff","B","B","tff/7f/ff/ff/6f/f7","B","B","B","tff/ff/ff/ff/ff/fe","B","tff/ff/ff/ff/df/7f","B","B","B","B","B"},
        {8,8,"tff/ff/bf/ff/ef/ff/ff/ff","tff/ff/ff/ff/7f/7f/ef/f7","B","tff/ff/f7/ff/e3/ff/7b/ff","tff/ff/ff/ff/ff/ff/ff/f5","B","B","B","tff/ff/ff/ff/ff/ff/ff/fd","tff/ef/ff/ff/ff/bf/ff/ff","ted/ff/fb/f7/ff/ef/ff/ff","tff/ff/ff/ff/ff/7f/ff/ff","B","B","B"},
        {7,10,"n3ff/3fd/3ee/3ff/3ff/3fb/3c9","t3eb/1ff/3ff/3fc/3ff/2f7/3ff","t3ff/3ff/2bf/3ff/3ff/3ff/3fe","t3ff/3fd/3ff/3ff/3ff/3ff/3ff","t3ff/3fd/3ff/3ff/3ff/3ff/3ff","t3ff/3ff/3ff/3ff/3ff/3ff/3ed","t3ff/3ff/3ff/3df/3ff/3fb/3ff","t3ff/3fe/3ff/3ff/3ff/3ff/1bf","n1ff/3ef/3ff/3ff/3ef/3ef/316","t3ff/3ff/3ff/3ff/3df/3ff/3ff","t3ff/3ff/3ff/3ff/3ff/3ff/1df","B"},
        {6,8,"tff/f7/be/ff/ff/ef","nff/ef/ff/5d/fd/fe","nff/f9/fd/b6/7f/a4","nff/ff/fe/df/ff/da","tff/fe/ff/ff/ff/df","tff/ff/ff/ff/ff/af","nff/ef/ff/f7/df/dd","nff/fb/ff/fa/42/34","nca/95/c6/c6/3d/80","ncf/af/f/4f/df/1f","nf2/f9/f7/f1/f8/e2","ndf/f6/57/75/eb/28","nfd/ff/ff/cf/df/fb","n5f/7f/bf/ff/ff/fe","tff/ff/ff/ff/7f/ff"},
        {9,10,"n1dd/3f3/3ff/27f/3bf/3ff/73/33f/280","n1f2/3d5/179/3e7/3ff/3ff/3ff/3de/11d","n3b2/a1/3c5/3c2/3f1/3ff/3ff/3ff/3ff","n3df/3ff/2bf/9b/161/28c/143/304/3c0","n1bf/3ec/3ed/159/7b/1c4/5/19/201","n3f6/99/37f/80/112/c0/100/74/1ca","n282/1ac/2fa/b9/391/a/64/2a/24b","n4f/38f/20f/cf/16f/bf/6f/3f7/113","n389/380/3a0/38d/3a0/3c0/3c0/3c0/3e8","n42/287/178/46/4/204/0/2/0","n3df/1ff/37f/3ff/92/29d/52/211/0","n1df/1ff/3ff/3ef/3bf/17f/11c/13a/40"},
        {9,8,"t0/0/80/0/0/0/0/0/8","W","ncf/7/1/2/0/0/0/0/0","nff/ff/ff/7f/3f/1d/7/7/3","ne0/f0/f0/f8/f8/fc/7c/7c/fd","t20/80/40/0/0/0/0/0/0","t2/8/0/2/10/0/0/0/8","t10/2/28/80/0/0/0/0/0","ta1/40/10/0/0/0/0/0/0","n33/12/1a/e/4/16/1/0/0","nf0/fe/f8/7f/3f/1f/f/57/32","n0/0/80/40/90/c0/f4/ff/fd","t20/84/21/0/0/0/0/0/0","t4/2/5/0/0/0/0/0/0","n2a/19/a/a0/1b/0/0/0/0"},
        {6,5,"t1/0/0/0/0/0","t1/0/10/0/0/0","W","W","W","W","n1b/1e/e/1e/1c/e","t1e/1e/1e/1f/1f/1f","t0/0/0/10/10/10","t0/0/0/0/1/0","n3/3/3/a/1f/1f","n18/c/1d/1f/1b/1e","n0/10/10/10/0/8","n0/0/0/0/0/f","n0/0/0/0/0/1d","t0/0/0/0/0/18","n0/1/0/0/0/1d","n17/10/6/8/8/2","n1f/1f/1f/7/7/1","n16/1a/1d/1e/1f/1f","t0/0/0/0/10/8","W","t0/0/2/0/0/0","W"},
        {10,6,"W","W","W","t0/0/0/0/0/0/0/1/0/0","W","n1f/3d/38/39/1c/18/16/1c/1e/3f","n3e/3e/3c/3c/38/39/38/39/39/39","n0/1f/f/9/3f/3f/c/24/1c/0","n1f/1/20/24/2f/7/29/1/9/18","n3f/2e/29/3/3a/34/30/1/13/3","n1f/4/11/22/13/2/0/18/2f/3e","n3f/0/3c/9/1d/31/3/3/0/20","n39/f/3f/8/21/21/20/20/0/0","n2e/2f/18/1b/3f/34/10/0/0/0","n22/a/21/15/20/20/0/0/0/1","n3/37/10/1/13/31/1/3/33/7","t3e/3f/3f/3f/3f/3f/3f/3f/3f/3f","n0/20/14/31/37/2f/2f/2f/26/26","n0/0/0/38/3c/3c/38/20/20/20","W"},
        {5,6,"W","W","W","t0/0/0/0/3","t0/0/0/0/4","n3c/32/38/28/35","n38/3d/3e/3e/3f","n32/23/0/0/20","n3c/6/0/0/0","n5/e/e/0/0","nf/1c/0/0/0","t20/0/0/0/0","W","W","t0/0/0/1/0","n3/b/13/17/f","n3f/3f/3f/3f/28","n20/21/20/20/20","n20/0/0/0/3e","W"},
        {10,8,"W","W","n37/3d/7f/77/7/6/0/0/1/1","nde/f6/f7/a7/2f/7/55/b3/b7/73","n97/d7/b3/db/7f/ec/7d/ff/f9/ff","ne0/f0/f0/fc/ff/ff/7f/ef/e7/c7","n0/0/0/0/0/e0/f8/f9/c3/4","n0/0/0/0/0/0/0/3e/27/c7","n0/0/13/1d/2d/6/de/ff/ff/ff","n0/0/0/c0/fe/ff/ff/fe/fe/ff","n0/88/1/83/0/ff/ff/ff/fe/7f","nc/3b/7c/82/7f/cf/cf/7f/d3/ff","n3c/f8/6f/7d/fd/ff/f4/e0/c4/c","n13/e/a8/f4/fc/84/a6/42/0/0","tc0/c0/40/c0/0/0/0/0/0/0"},
        {6,8,"W","W","n12/17/2d/76/6e/71","n53/f3/c0/c1/40/83","nff/ff/ff/ff/2/bd","nf0/e0/9b/13/19/68","ne1/e0/f1/e6/1f/bf","n7/5/9f/9d/ff/fe","nff/ff/ff/7f/1f/5f","tff/ff/fe/fe/fb/ff","tff/ff/ff/ff/7f/7f","nf2/fe/fc/f0/ae/bc","t8/0/0/0/0/0","W","W"},
        {5,6,"W","W","t1/0/0/0/0","t8/0/0/0/30","n37/20/0/0/3c","n23/21/1/1/10","n3/e/1e/27/0","n20/24/12/3f/34","n1f/3f/3f/1f/17","B","n3d/3e/3f/f/37","n3b/19/3e/3f/23","n3e/3f/3f/2f/f","n2d/37/2a/35/3b","n3f/21/7/b/2f","n3f/3b/3c/1c/20","W","W","W","W"},
        {9,8,"W","W","t8/73/1/0/0/0/0/0/0","t62/c0/0/0/0/0/0/0/0","te0/0/0/0/0/0/0/0/0","nc/7/3/7/7/f/7/4/0","n3f/5f/fb/df/f7/ef/5c/f8/60","nfc/ff/ff/ff/3f/1f/1f/e/f","n99/59/db/83/86/c1/c0/a0/fb","n1f/87/ed/e7/e1/c0/40/60/f0","n8b/8c/8e/8a/81/7/0/0/0","t0/0/0/0/0/80/40/0/0","W","W","W"},
        {8,6,"W","W","W","W","W","W","W","W","W","W","n3f/3f/f/13/7/3/b/f","n2f/3c/21/30/38/3f/3f/3e","n30/0/0/20/0/30/20/38","t0/0/0/0/0/18/8/2","n20/31/1b/29/8/4/0/0","W","W","W","W","W"},
        {9,10,"W","W","W","W","W","W","nef/ef/7f/3d/bf/19f/1df/df/2ef","n3ee/3fa/3d9/3f9/3ff/3fa/3fc/3ff/3ff","n41/263/200/264/3f8/3e0/3e0/3c0/3e0","W","W","W"},
        {8,5,"W","W","W","W","W","W","W","W","W","W","W","n0/0/0/0/1/f/b/17","t1f/f/1f/f/1f/1f/1b/1b","tf/1f/1f/1f/1f/1f/1f/1f","t1f/1e/17/1f/1f/1f/1f/1f","n17/f/f/e/16/17/16/1f","t1e/1f/1e/1f/1f/1f/1f/1f","n0/10/0/10/18/18/18/18","W","W","W","W","W","W"},
        {7,5,"W","W","W","W","W","W","n0/0/0/1/0/1/5","n0/2/8/9/2/a/15","n0/0/0/4/13/e/1b","n0/4/d/b/3/12/15","n3/10/2/1c/6/1f/19","n7/16/1f/d/16/1c/1d","nb/5/1f/1f/1d/1f/1f","t1f/1f/f/1f/1f/1f/1f","B","t1f/1f/1f/17/17/17/1f","n1f/1f/1f/1b/1/13/1f","t1e/1f/1f/1f/1f/1f/1f","n0/14/1e/1f/1f/1f/1f","n0/0/0/18/1f/1e/1f","t0/0/0/0/0/10/18","W","W","W"},
    }
end

function get_level3()
    return {
            {9,10,"B","B","B","B","n3ff/3ff/3ff/3ff/3fe/3f8/3fc/3f0/3d0","n3ff/3ff/3ff/1ff/ff/1ff/3db/3e0/0","t3ff/3ff/3ff/3ff/3ff/3ff/37f/1ff/c7","B","B","B","B","B"},
            {10,5,"B","B","B","B","B","B","B","n1f/1f/1f/1f/1e/1e/18/19/11/7","n1d/1d/1a/14/0/0/0/0/0/0","t10/0/0/0/0/0/0/0/0/0","W","W","W","t3/0/0/1/0/0/0/0/1/1","n1d/8/12/18/0/0/6/7/1b/11","n1f/1f/f/1f/f/f/0/1/18/18","t1f/1f/1f/1f/1f/1f/1f/1f/1f/0","n1f/1f/1e/1e/1f/1f/1c/1c/18/0","t1f/1f/1f/1f/1f/1f/1f/f/f/7","B","B","B","B","B"},
            {5,10,"B","B","B","n3c7/3c4/3c4/3c0/380","W","W","n0/0/f/c/f","n3c/24/200/1f/3ff","n0/3/26d/3ff/3ff","t1ff/3ff/3ff/3ff/3ff","B","B"},
            {8,6,"B","B","B","B","t3f/3f/3f/3f/3d/3b/3f/3e","n38/38/30/30/30/30/30/30","W","W","W","n0/0/0/2/0/10/18/10","n3/6/3f/3/7/e/1d/12","n3e/3c/34/38/6/c/30/0","n15/13/18/38/0/0/0/0","n3f/3f/0/0/0/0/0/0","n3f/33/0/0/0/0/0/0","n3f/3f/f/7/0/0/0/0","n3f/3f/3f/3f/3f/1f/1f/7","B","B","B"},
            {5,10,"B","B","n3fe/3fe/3fe/3fe/3f6","t300/200/300/0/0","W","t10/0/0/0/0","t240/0/0/0/0","W","W","n3/3/7/3/3","B","B"},
            {8,8,"B","B","tff/ff/ff/ff/ff/fe/fe/fc","n18/d0/d8/98/98/98/a/12","W","n0/0/3/3/3/0/0/4","n0/80/80/0/0/20/60/60","n0/c0/c0/c0/80/0/0/0","W","W","W","t0/0/0/4/0/2/0/0","n1f/f/6f/7/2b/fa/19/1f","tff/ff/ff/ff/f9/ff/fe/7f","B"},
            {7,5,"B","B","B","t1f/1f/1f/1f/1e/1f/1f","n19/1e/f/f/1d/1d/1c","n4/e/e/f/16/12/1f","W","n0/0/0/4/4/4/c","n0/1/1/3/3/2/6","n13/17/16/16/16/0/1","t0/0/8/0/0/0/0","W","W","n0/0/0/0/0/1/13","n0/0/0/0/0/0/1b","n0/0/0/1e/6/f/1f","n0/0/0/0/f/1c/1f","n0/0/0/0/e/1f/1f","n0/0/0/0/10/1f/1f","n3/0/0/1/0/10/1e","n15/1f/1f/f/f/f/3","nf/7/17/1b/1f/1f/1f","B","B"},
            {7,6,"B","B","n3f/3f/3e/3c/3c/3e/3a","t2/4/0/0/0/0/0","t1c/0/0/0/0/0/0","n30/30/28/8/c/d/c","n30/30/30/20/30/30/21","n31/33/1/5/38/3c/1e","t30/30/0/0/0/0/0","n0/0/3/7/1f/1f/3f","n7/1f/3f/3f/3f/3f/3e","n3c/38/38/30/20/20/10","n3f/1f/f/17/7/3/1","t3f/3f/3f/3f/3f/1f/3f","B","B","t3e/3f/3f/3f/3f/3f/3f","n7/27/3f/3d/3f/3f/3e","t3b/3f/3b/3b/3f/3f/37","B"},
            {10,8,"B","tff/fd/fd/ff/ff/fd/ff/ff/fe/f6","n0/40/c2/c2/81/8d/8f/e7/71/df","n0/0/0/0/0/88/80/d8/dc/c0","nf8/f0/f0/f0/70/30/30/30/10/18","n30/39/17/13/23/3/1/1/1/13","tcf/ff/ff/ff/ff/ff/ff/ff/ff/ff","tff/ff/ff/ff/fb/f3/ff/ff/ff/bf","n0/0/80/c0/c0/c0/c0/c0/84/ff","t1/0/0/0/0/0/0/0/0/0","nbf/f/3d/12/12/16/1f/1f/1f/1f","tff/ff/ff/ff/ff/3f/7f/7f/ff/ff","tff/ff/ff/ff/ff/f7/e3/e1/ff/ff","tff/f4/fd/fd/ff/fd/ff/ff/ff/ff","tff/ff/ff/ff/7f/bf/ff/ff/ff/ff"},
            {9,10,"t3ff/3ff/3ff/3ff/3ff/3fe/3ff/3ff/3ff","n3d9/3db/3ff/3ff/3c7/3df/393/38f/34f","n2e0/3f5/3f9/3f8/3b6/332/33f/3ff/3ff","n1a/b/3/0/0/200/200/201/200","n5f/25f/24f/f/10/0/80/180/28c","n3ff/3f7/3ff/3fe/3fc/3f8/3f8/3f0/1e0","n3ff/300/0/0/7f/c0/100/4/7f","n3e0/3b0/0/0/0/180/c0/c0/340","n3f/1f/1f/1f/1f/1c/3f/3d/3f","n3ff/3ff/3ff/3f4/3f8/c/1fe/3ff/3ff","n3ff/3ff/3ff/ff/7f/7f/7f/3f/23f","B"},
            {5,8,"B","nfe/ff/ff/e3/fb","tff/ff/ff/ff/f7","tff/ff/ff/ff/fa","n0/20/90/b0/b9","n63/21/21/19/18","nbe/be/9c/dc/d8","n13/1c/0/0/0","nff/fc/fc/78/1","t80/60/20/0/0","nf/f/7/3/3","n7f/3f/ff/df/47","tf8/fe/ff/ff/ff","tff/ff/ff/ff/7f","B"},
            {5,8,"B","nc1/e3/c7/9f/ff","tf7/ff/ff/ff/ff","tfa/ff/ff/ff/ff","n6c/fc/fc/fb/fc","n18/8/8/26/0","nf8/38/8/28/0","W","W","W","t1/2/0/4/0","t9/0/0/0/0","nf0/77/3/1/2","tff/ff/ff/bf/ff","B"},
            {6,10,"B","B","B","n3fd/3f8/3f8/3f4/3f8/3d8","t10/0/108/100/4/200","W","W","W","t8/8/4/0/c/0","W","n3f/f/1f/7f/df/3f","B"},
            {5,10,"B","B","B","n3e7/3fc/3dd/3fb/3f9","n3/200/0/180/380","t0/0/0/260/60","W","t0/0/7/4/0","n2/f/1f/23d/f4","W","n3f/3f/3f/7f/3f","B"},
            {7,6,"B","B","B","B","B","t3a/3e/3f/3f/3f/3f/3f","n7/33/3b/3b/3b/3b/33","n30/38/38/38/3c/3c/3e","t4/0/2/0/0/0/0","n20/20/10/10/38/18/18","W","W","t0/0/0/0/0/0/e","n1/0/0/0/0/1/3f","n0/0/0/0/1/21/3f","t0/0/0/0/10/30/20","n0/1/1/3/f/7/7","t1f/3f/3f/3f/3f/3f/3f","B","B"},
            {5,10,"B","B","B","t3de/3ef/3ff/3ff/3fe","n3f8/3e8/3ec/3d4/1e6","tc/8/0/0/0","W","t71/0/0/0/0","n3ff/8/c/8/240","n207/3/7/7/f","B","B"},
            {8,5,"B","B","B","B","B","B","B","B","nf/f/f/d/7/4/0/1c","n16/e/8/c/1c/18/18/0","t0/0/0/10/8/0/8/0","W","W","W","W","W","t3/0/0/0/0/0/0/0","t0/0/0/0/0/0/1/1","n0/0/1/3/7/1f/1f/1f","t7/1f/1f/1f/1f/1f/1f/1f","B","B","B","B"},
            {9,6,"B","B","B","B","B","B","n3e/3f/3f/3e/3e/3e/3c/3c/3e","t20/0/20/0/10/0/0/10/10","W","W","W","W","W","n0/0/0/0/3f/3f/f/f/f","n7/7/7/f/3f/3f/3f/3f/3f","B","B","B","B","B"},
        }
end

function get_level4()
    return {
        {7,5,"B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B","B"},
        {5,10,"B","B","B","B","n3ff/3ff/3de/3f7/2fa","n3f7/2fd/3f9/3ea/3ff","n3ff/ff/33b/15c/31c","t3ff/3ff/3ff/1ff/2ff","B","B","B","B"},
        {5,8,"B","B","B","tff/ff/ff/ff/fe","ne0/c7/83/3d/a9","nff/e5/6/bf/ff","n9f/fc/e0/c1/c7","nfe/ff/7f/cd/36","n1b/86/e1/7c/df","n7f/1f/1f/cf/cf","B","B","B","B","B"},
        {5,8,"B","B","tff/ff/ff/fe/ff","nf6/b5/e2/f5/b","n6b/77/ff/6f/1f","nf1/97/0/b1/45","n82/38/1/83/7","nac/f0/fe/4d/ba","n7c/1f/6f/af/be","n27/7f/7f/df/ff","B","B","B","B","B"},
        {7,8,"B","B","nfd/ff/ff/ff/f9/f0/f9","n38/1a/d0/3b/90/e5/e6","n1c/3a/5e/bf/3f/3f/7b","na1/6c/f6/ff/5a/fc/85","n5f/27/4c/7a/8c/af/56","ncf/3/27/fb/f3/ef/bf","nf/ff/df/ef/cf/e3/a7","tfd/ff/ff/ff/ff/ff/ff","B","tff/ff/ff/7f/ff/ff/ff","B","B","B"},
        {6,10,"B","t3ff/3fb/3fc/3ff/3fe/3fd","n42/35/d5/8/34c/92","n2f6/27c/70/74/fc/ff","nce/3c4/2c2/1e5/16d/3c6","nea/c0/2d4/1e0/15f/ff","nd2/37b/fb/1cf/30f/3df","n37e/2ed/37d/2ff/3ff/35f","B","B","B","B"},
        {8,8,"B","B","nb4/ea/f8/fc/f8/e8/f8/d2","n1/40/e7/0/7/c5/59/c9","n7e/7e/7d/fc/be/ff/ff/fe","n33/3f/9b/f/3f/5b/7f/bf","tff/ff/ff/fe/fa/f4/ff/ff","nfd/7e/1f/f/bf/7b/f3/fb","nef/ff/ff/df/ef/ef/c7/cf","nff/ff/fb/fb/ba/b2/bb/3f","B","B","B","B","nfd/ff/ff/ff/ff/fe/fc/f0"},
        {5,5,"B","B","B","n1f/1e/1c/1f/1f","n15/1b/1d/8/1a","n0/10/10/2/10","nf/3/f/1f/1f","B","nf/f/f/1e/1f","B","B","t1f/1f/1f/1f/1d","n1b/1b/1d/1f/1f","t17/1f/1b/1f/1f","t1e/1f/1f/1f/1e","t1f/1f/1f/1f/f","B","B","B","B","t1f/1f/1f/1f/7","n17/1c/1c/1d/1f","na/15/c/3/1e","n0/0/0/18/12"},
        {6,5,"B","t1f/1f/1f/1e/1f/1f","t1f/1e/1f/1f/1f/1f","n13/11/1b/f/17/1f","n14/1d/1e/9/13/1f","n1/4/f/1d/11/1d","nf/f/1f/1f/f/1e","n1f/1f/1b/13/17/b","B","B","n1f/1e/1d/19/12/10","n18/3/d/c/0/9","n1f/1f/7/f/17/f","t1f/f/1f/1f/1f/1f","n19/1f/1c/1f/1f/1f","tf/1f/1f/1f/f/f","B","B","B","n1f/17/17/1d/1e/1f","n1b/1d/1b/17/a/7","n1f/1f/17/e/e/f","n1f/1f/1f/0/1f/1f","n1f/1e/1b/f/f/1f"},
        {8,10,"B","B","t1ff/3ff/3ff/3ff/3ff/3ff/3ff/3ff","n3db/342/394/3a8/3f4/3f8/3b8/3b0","n3ff/1ef/ff/7f/7f/ff/7f/205","n288/38c/296/301/397/3e0/3fa/3f0","n3f/3f/3f/1f/7/0/4/124","n377/3fe/3ff/3ff/37f/3fd/3fc/3ec","n3ff/3fd/37b/3fd/3f3/3fd/3f9/3ff","n3fd/3e8/3fa/3dc/3f9/2fe/278/394","n25a/13d/318/1c/10c/1c/80/8f","n3ff/29f/ff/3ff/bf/ff/1df/ff"},
        {8,8,"B","B","B","B","nf8/f4/e0/ef/ff/fe/ff/ff","n4/c6/7/0/90/c0/f8/d3","nff/ff/7f/3f/1f/f/95/a","ncc/ea/c4/fe/fc/d0/98/8d","n3d/1b/32/15/1/0/0/82","nff/fd/ff/3f/37/ae/3c/f0","nff/df/e1/f4/6f/f4/77/d","nbe/fe/f9/d0/c0/b2/7f/c7","n39/34/ad/63/6e/84/e0/ba","n6/27/7c/bf/ae/8e/d7/82","n7f/7f/bf/ef/f3/b3/8f/cf"},
        {7,8,"B","B","B","B","tff/ff/ff/ff/ff/f9/ff","nec/eb/fb/de/78/79/e0","n86/c9/4/4/8/28/0","nd0/7e/26/f/1f/47/3","n23/1/8/61/4/bc/c0","n18/88/8/94/70/80/40","W","n7b/77/15/9b/1b/0/0","nfb/e4/f6/f9/bd/bf/f7","n15/84/b4/70/3f/9f/d7","n3d/9f/7f/57/5f/ff/9f"},
        {8,6,"B","B","B","B","B","B","n2c/2f/39/3b/1b/3c/3d/3e","n20/20/1c/34/31/34/30/33","n1c/11/0/4/0/6/0/0","n0/25/4/0/15/16/d/29","t1f/1e/3f/3f/3f/3f/3f/2f","n20/2c/30/30/38/3a/3c/38","t0/8/0/0/0/0/0/0","W","t0/0/0/8/0/0/0/0","t0/0/4/0/0/0/0/0","n3f/1d/7/0/0/0/0/0","n2f/36/35/0/8/0/0/8","n1f/e/e/36/2b/39/31/39","n1b/27/1a/f/1d/3b/3f/3f"},
        {6,8,"B","B","B","B","tff/ff/fb/ff/ff/ff","n70/f0/f6/fb/f6/ff","n5/0/32/2b/e9/e9","nf7/6f/15/65/21/f9","nfe/fa/f8/fa/fc/fc","t0/80/0/0/0/0","W","t0/0/0/0/0/1","n1/1/2/1/3/7","nec/df/9f/ff/ff/7f","n7b/f/1f/ff/9f/ff"},
        {8,10,"B","B","B","t3ff/3ff/3ff/37f/3ff/3ff/3ff/3ff","n3f6/3fb/2bf/3da/3bd/35d/3b5/1f6","n23d/3b1/328/335/2a3/195/6f/37f","n3ff/3ff/ff/1fb/3f7/3e6/3cc/30c","n280/0/0/3c0/3b4/12/7/0","t0/0/80/0/0/0/0/200","n183/2b/1d/10f/3f/ff/30f/3ff","n27f/3ff/3ff/3ff/3df/3ef/383/3e2","t3ff/3f3/3fb/3ff/3ff/3ff/3ff/3f7"},
        {5,8,"B","B","B","B","tff/ff/bf/f5/fd","tfd/ff/f7/bf/fe","n8f/3f/7f/ff/77","nf8/f0/f1/e6/f1","n70/e4/c0/90/80","n66/89/2f/1b/7","nc2/80/9f/85/80","n6a/ec/80/62/0","ncf/1f/10/1c/f","nf8/f4/0/24/ff","nff/ef/77/2b/e7"},
        {5,6,"B","B","B","B","B","n3d/29/31/20/28","n3f/7/e/21/5","n3f/27/2f/3f/38","n3b/3f/16/27/0","n3c/1e/3c/3a/12","n0/10/7/2/1b","t0/0/1/1/2","n0/d/2/20/2","n34/38/19/28/17","n0/28/7/8/3d","n0/0/3/22/1","n7/7/37/3f/1f","t3f/3f/3f/3f/1d","n3f/3f/3e/2f/25","n39/18/3e/3f/3f"},
        {6,8,"B","B","B","nfe/fc/fc/f8/f0/d0","n4/a/c/1/b/17","nf4/d0/5/61/0/4","n7d/89/b/27/8/9c","ncd/ea/e/1e/d2/aa","nc0/c0/40/40/e6/86","n66/2/2/5/3/b","nf8/0/0/81/a5/e0","nd3/4/1c/1d/a4/5","nff/3f/1f/9/f7/ff","nff/ff/71/7/f7/ff","naf/57/d2/fa/f8/10"},
        {5,6,"B","B","B","t3f/3f/3f/3f/3c","n30/20/0/0/10","n1/5/3/7/3f","n38/3e/3e/3d/3e","n8/18/21/a/37","n25/12/22/13/1e","n2e/1b/3f/3f/17","ne/38/30/30/20","n3/a/19/1/0","n14/0/0/0/1d","t3d/3f/3f/2f/2f","n28/29/0/0/20","n26/21/33/5/0","n1f/3f/27/1a/3b","n3f/3c/32/1f/3f","n1d/0/1/1/3f","n2a/3/30/1a/23"},
        {8,8,"B","tff/ff/ff/ff/ff/ff/ff/fe","nf9/f9/f0/e8/e0/d8/92/0","n0/c0/d/48/0/0/5/6","nff/ff/ff/fe/fe/fd/7f/3b","na2/ff/fc/bf/7f/fd/ff/fb","nb9/37/6f/3e/ce/9c/e0/e0","nfc/f0/e0/0/1/0/0/0","n26/1b/1/27/21/0/0/3","n1e/5a/3f/df/ff/fa/e7/e3","nf0/d1/fc/fb/b6/ca/cb/7f","n1/ff/fe/94/40/6/2f/f7","nff/5b/7f/7f/f7/7f/f3/f5","nfe/ec/fe/f7/bb/7f/ff/ff","nb2/10/5a/ff/ff/ff/ff/ff"},
    }
end

__gfx__
000000007777777766666666aaaaaaaa000000006666666600000000888888887777777777777777000000000000000000000000000000000000000000000000
000000007777777766666666aaaaaaaa077777706666666600000000800000087777777777777777000000000000000000000000000000000000000000000000
007007007777777766666066aaaaaaaa077778706686686600800800800000087777777777877877000000000000000000000000000000000000000000000000
000770007777777766660666aaaaaaaa077787706668866600088000800000087777777777788777000000000000000000000000000000000000000000000000
000770007777777766606666aaaaaaaa077877706668866600088000800000087777777777788777000000000000000000000000000000000000000000000000
007007007777777766066666aaaaaaaa078777706686686600800800800000087777777777877877000000000000000000000000000000000000000000000000
000000007777777766666666aaaaaaaa077777706666666600000000800000087777777777777777000000000000000000000000000000000000000000000000
000000007777777766666666aaaaaaaa000000006666666600000000888888887777777777777777000000000000000000000000000000000000000000000000
77000770077077707770777007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070700070707070777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070700077007770707077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070707070707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707700777070707070707077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000101010303030303030303010301030101030303030101030003010303030101030303010303030103030103030301030100000000000000000
00000000000000000000000000000000000000000000003010101010101010103030301030101010103010301030103010103010101010303010301030301010
00000000000000303030103030303010101010301010101010101010101030003010103030303030303030301010103010101010103030100000000000000000
00000000000000000000000000000000000000000000001010101010101010101030303010303030301030303010101030101030101010103030103030101010
00000000000000303030103030301030101030303030303030303030303030001030301030303030303030303030103030301030103030100000000000000000
00000000000000000000000000000000000000000000003030303010103030303010303030301030303030103010101010101010101010101030103010101010
00000000000000303030301010103030303030301030303030303030301030001030103010303030303030301010303030303030303010100000000000000000
00000000000000000000000000000000000000000000003030303010103030303030303030301030303030301030303030303030303030301030303010101000
00000000000000303030303030303030303010103030303030303030303010001030103030103030303030301030101010101010101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000030301010101010101030303030303030303010303010101030101010101000
00000000000000303030303030303030301030303030301010101010303030003010303010301030303030301030101030101030101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000030103030301030303010303030101030301030103030101030301010101000
00000000000000303030303030303030101010303030303010101010103030003030103010303010303030301030103010101010301030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010103010303030103010103030101030303030103010101030101010101000
00000000000000303030301010101030303030303010303030101010103030003030301030301030103030301030103010101010301030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101030301030301010103010303010103010303010101030101010101000
00000000000000303030303030103030303030303010103030301010103030003030303010301030301030301030101030101030101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101010103010101010101030303030101030301030103010303030303000
00000000000000303030303010303030303030303010101030303010103030003030303030103030103010301030103030303030301030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101010103010101010103010101010101030301030103010103010301000
00000000000000303030301010101030303030303010101010303030103030003030303030301030103030101030103010303010301030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101010303010101010103030303010303030301010301010103010301000
00000000000000303030303030303030303030303010101010103030303030003030303030303010303030101030101030303030101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101010101010101010103030301030103030301030103010103010301000
00000000000000101010103030303030303030303030101010101030303030003030303030303030101010301030101010303010101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101030303030301010103030103010301030301030103010303030303000
00000000000000303010303030303030303030103030303030303030303010003030303030303030303030301030101010101010101030100000000000000000
00000000000000000000000000000000000000000000000000000000000000000010101010101010101010103030103010301030303030301010101030303000
00000000000000301030303030303030303030301030303030303030301030003010101030101010103010303030303030303030303030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000010303030303030303030103010301010103010303010103010103010103000
00000000000000101010103030303030303030000000000000000000000000003010303030101010103010303030303010101010303030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030101030303030301010303010303030303010303010303030303030103000
00000000000000303010301030303030101030000000000000000000000000003010101030101010103010303030301010101010103030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030101010101010101010301030303030103030103010303030303030103000
00000000000000301030103030303010301030000000000000000000000000003010303030101010103010303030101030303030101030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030301010101010101030301030301010301030103030301030301030303000
00000000000000103010303030301030103030000000000000000000000000003010101030101010103010303010103030303030301010300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030301010303030101030301030103030301030103030301030301030303000
00000000000000101030301010301010303030000000000000000000000000003010303030101010103010303010103030303030301010300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030101030303030301010301030103030303010101010101030301010101000
00000000000000303030103010303030303030000000000000000000000000003010101030303030303010303010103030303030301010300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030101030303030301010301010303030303030101010101030301010101000
00000000000000303010301030301010303030000000000000000000000000003010303010101010101010303010103030303030301010300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030101030303030301010301030303030303030301010101030301010101000
00000000000000303010103030103010303030000000000000000000000000001030101010101010101030103030101030303030101030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030301010303030101030300000000000000000001010101030301010101000
00000000000000303030303010301030301010000000000000000000000000001030101010101010101030101010301010303010103010100000000000000000
00000000000000000000000000000000000000000000000000000000000000000030303010303030103030300000000000000000001010103030303010101000
00000000000000303010103010103030103010000000000000000000000000001030303030303030303030103010101030303030101010300000000000000000
00000000000000000000000000000000000000000000000000000000000000000030301030303030301030300000000000000000001010103030303010101000
00000000000000301030103030303010301030000000000000000000000000001010101010101010101010103030103030303030301030300000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000103010303030301030103030000000000000000000000000001030303030303030303030100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000101030303030301010303030000000000000000000000000001030103030303030303030100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001010101030303010301030100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001030103010301030303030100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001030303030303030303030100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001010101010101010101010100000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000077000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000000000007000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000000000007000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000000000007000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777000000000000077700000000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000007770000077700000770000007700000077700000770000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000070000000700000070000000700000070000000070000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000770000077700000070000000700000077700000070000000000000000000000000000000000000000000000000000000000000000000
00000000000070000000070000070000000070000000700000000700000070000000000000000000000000000000000000000000000000000000000000000000
00000000000777000007770000077700000777000007770000077700000777000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
07770777055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
00070007055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
00770077055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
00070007055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
07770777055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
00000000055000000550000005500000055777777550000005500000055000000550000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
07700770055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
07770777055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00000000055777777550000005577777755777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
00000000055555555555555555555555555555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000
07770770055777777550000005500000055777777557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00070070055777777550000005500000055777777557777775500000055777777557777770000000007777770007777770000000007777770000000000000000
07770070055777777550000005500000055777777557777775500000055777777557777770000000007777770007777770000000007777770000000000000000
07000070055777777550000005500000055777777557777775500000055777777557777770000000007777770007777770000000007777770000000000000000
07770777055777777550000005500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
00000000055777777550000005500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
00000000055555555555555555555555555555555555555555555555555555555557770007770007770007770007770007770007770007770077777777700000
00000000055555555555555555555555555555555555555555555555555555555557770007770007770007770007770007770007770007770077777777700000
07700770055777777557777775500000055777777557777775500000055777777557770007770007770007770007770007770007770007770077777777700000
00700070055777777557777775500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
00700070055777777557777775500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
00700070055777777557777775500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
07770777055777777557777775500000055777777557777775500000055777777557770007770007770007770007770007770007770007770000000000000000
00000000055777777557777775500000055777777557777775500000055777777557770007770007777770000007770007770007777770000000000000000000
00000000055555555555555555555555555555555555555555555555555555555557770007770007777770000007770007770007777770000000000000000000
00000000055555555555555555555555555555555555555555555555555555555557770007770007777770000007770007770007777770000000000000000000
07700770055777777557777775577777755000000557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777557777775577777755000000557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777557777775577777755000000557777775500000055777777550000000000000000000000000000000000000000000000000000000000000
00700070055777777557777775577777755000000557777775500000055777777550007777770007777777770007777777770007777777770000007777770000
07770777055777777557777775577777755000000557777775500000055777777550007777770007777777770007777777770007777777770000007777770000
00000000055777777557777775577777755000000557777775500000055777777550007777770007777777770007777777770007777777770000007777770000
00000000055555555555555555555555555555555555555555555555555555555557770000000007770007770007770007770007777777770007770000000000
00000000055555555555555555555555555555555555555555555555555555555557770000000007770007770007770007770007777777770007770000000000
00000770055777777557777775577777755777777550000005577777755777777557770000000007770007770007770007770007777777770007770000000000
00000070055777777557777775577777755777777550000005577777755777777557770000000007777770000007777777770007770007770007777777770000
00000070055777777557777775577777755777777550000005577777755777777557770000000007777770000007777777770007770007770007777777770000
00000070055777777557777775577777755777777550000005577777755777777557770000000007777770000007777777770007770007770007777777770000
00000777055777777557777775577777755777777550000005577777755777777557770007770007770007770007770007770007770007770000000007770000
00000000055777777557777775577777755777777550000005577777755777777557770007770007770007770007770007770007770007770000000007770000
00000000055555555555555555555555555555555555555555555555555555555557770007770007770007770007770007770007770007770000000007770000
00000000055555555555555555555555555555555555555555555555555555555557777777770007770007770007770007770007770007770007777770000000
00000000000000000000000000000000000000000000000000000000000000000007777777770007770007770007770007770007770007770007777770000000
00000000000000000000000000000000000000000000000000000000000000000007777777770007770007770007770007770007770007770007777770000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005555555555555555555555555555555555555555555555555000000000000000000000000000000000000000
00000000000000000000000000000000000000005777777750000000577777775000000057777777500000005000000000000000000000000000000000000077
00000000000000000000000000000000000000005777007750007700577070775007770057770777500077005000000000000000000000000000000000007777
00000000000000000000000000000000000000005770777750070700577070775007070057707777500700005000000000000000000000000000000000777777
00000000000000000000000000000000000000005770777750070700577000775007770057777777500777005000000000000000000000000000000077777700
00000000000000000000000000000000000000005770707750070700577770775007070057777777500007005000000000000000000000000000007777770000
00000000000000000000000000000000000000005770007750077000577000775007070057777777500770005000000000000000000000000000777777000000
00000000000000000000000000000000000000005777777750000000577777775000000057777777500000005000000000000000000000000077777700000000
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000
00000000577777775000000057777777500000005777777750000000577777775000000057777777500000005777777750000000577777775000000050000077
00000000577007775007770057700077500707005777777750077700577000775007770057700777500777005770007750077000577700775000770050007777
00000000577070775007070057707077500707005777777750070700577070775000700057707077500070005777077750070700577077775007000050777777
00000000577070775007770057700777500770005777777750077700577000775000700057707077500070005777077750070700577077775007770057777777
00000000577070775007070057707077500707005777777750070000577070775000700057707077500070005777077750070700577070775000070057777777
00000000577000775007070057707077500707005777777750070000577070775007770057707077500070005770007750070700577000775007700057777700
00000000577777775000000057777777500000005777777750000000577777775000000057777777500000005777777750000000577777775000000057770000
00000000555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555557000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770000000000777777777700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000077777777770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700000000007777777777000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770000000000777777777700000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000077777777770000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700000000007777777777000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000007777770000000000777777777700000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000077777777770000000000000000007777
00000000000000000000000000000000000000000000000000000000000000000000000000000077777700000000007777777777000000000000000000777777
00000000000000000000000000000000000000000000000000000000000000000000000000007777770000000000777777777700000000000000000077777777
00000000000000000000000000000000000000000000000000000000000000000000000000777777000000000077777777770000000000000000007777777777
00000000000000000000000000000000000000000000000000000000000000000000000077777700000000007777777777000000000000000000777777777777
00000000000000000000000000000000000000000000000000000000000000000000007777770000000000777777777700000000000000000077777777777777
00000000000000000000000000000000000000000000000000000000000000000000777777000000000077777777770000000000000000007777777777777700
00000000000000000000000000000000000000000000000000000000000000000077777700000000007777777777000000000000000000777777777777770000
00000000000000000000000000000000000000000000000000000000000000000777770000000000777777777700000000000000000077777777777777000000
00000000000000000000000000000000000000000000000000000000000000077777000000000077777777770000000000000000007777777777777700000000
00000000000000000000000000000000000000000000000000000000000007777700000000007777777777000000000000000000777777777777770000000000
00000000000000000000000000000000000000000000000000000000000777777000000000777777777700000000000000000077777777777777000000000000
00000000000000000000000000000000000000000000000000000000077777700000000077777777770000000000000000007777777777777700000000000000
00000000007770707000007070707077707070777000000000000007777770000000007777777777000000000000000000777777777777770000000000000000
00000000007070707000007070707070007070070000000000000777777000000000777777777700000000000000000077777777777777000000000000000000
00000000007700777000007070707077007770070000000000077777700000000077777777770000000000000000007777777777777700000000000000000000
00000000007070007000007070777070007070070000000007777770000000000777777777000000000000000000777777777777770000000000000000000000
00000000007770777000000770070077707070770000000777777000000000077777777700000000000000000077777777777777000000000000000000000000
00000000000000000000000000000000000000000000077777700000000007777777770000000000000000007777777777777700000000000000000000000000

__map__
0303030103030301010101010101010303010103030101010303030101010303030303030303010103030303030303010101010101030303000000000000000000000000000000000000000000000000000000000000010103030303030303030100030303030103030303030303030103030103030101030101010101030101
0103010101030101010101010101030303030103010103030101010303010103030303030301030103030303030101030303030303010103000000000000000000000000000000000000000000000000000000000000010301030101010101030100030303030103030303030303030301030301030103030301010103030301
0103030101030101010101010101030301030301010303010303030103030101030303030103030103030303010303030303030303030301000000000000000000000000000000000000000000000000000000000000010301030101010101010300030303030103030303030301030103030103030103030303030303030301
0101030101030101010101010103030303030101030301010103010101030301010101010303030101010101010101030303030303010101000000000000000000000000000000000000000000000000000000000000010301030101030101010300010303010301030301030103030303010303030103030303030303030301
0101010301030101010101010303030303030101030101010103010101010301010303030303030303030301010303010101010101030301000000000000000000000000000000000000000000000000000000000000030101030101030101010300010301030303010301030301030303030103030303030303030303030303
0101010103010101010101030303030303030101030101010303030101010301030103030303030303030103010303030303030303030301000000000000000000000000000000000000000000000000000000000000030103010103010301010300010103030303030101030303030101030303030303030103030301030303
0101030301010001010103030303030303030101030301010303030101030301030301030303030303010303010303030303030303030301000000000000000000000000000000000000000000000000000000000000030103010303010303010300010303030303030301030301010303010103030303030303010303030303
0101030301010001030303030303030303010103030301030303030301030303030103030303030301030303010303030303030303030301000000000000000000000000000000000000000000000000000000000000030103010101030101010300030103030103030103030103030303030301030103030301030103030301
0101030301010003030303030303030303010103030303010303030103030303010303030303030103030303030103030303030303030103000000000000000000000000000000000000000000000000000000000000030103010303010303010300030301030103010303010303030303030303010101030303030303030101
0103030303010001010103030303030301010103030303010303030103030303010303010103030103030303030103030303030303030103000000000000000000000000000000000000000000000000000000000000030103010301010103010300030303010101030303010303030303030303010303030303010101010103
0103010103010001010101010301030101010103030301030101010301030303010301030301030103030303030301030303030303010303000000000000000000000000000000000000000000000000000000000000030103010101010101010300030303030103030303030101010101010101030303030303030303030301
0303010103030001010101010303030301010103030103030101010303010303010103030303010103030303030303010101010101030303000000000000000000000000000000000000000000000000000000000000010303030303030303030301010103030303030303030001010303030301010303030303010101010301
0301010101030003030303010103030303030303030103030303030303010303010101030303030303010101010103030303030303030101000000000000000000000000000000000000000000000000000000000000000101010303030301010103010101010103030303030001030303030303010303030303030303010301
0303010301030003030301030101030303030303010101010303030101010103010103010101010101030101010303010101010101010301000000000000000000000000000000000000000000000000000000000000000101030303030303010103030101030301030303030001030303030303010303030303030303010103
0301030103030003030103030301010303030301010303030103010303030101010303010101010101030301030101010101010101010103000000000000000000000000000000000000000000000000000000000000000103030303010103030103030103010303010303030003030301010303030301010101010103010303
0303010301030003010303030303010303030301030303030103010303030301030103010101010101030103030101010303030301030103000000000000000000000000000000000000000000000000000000000000000303030301010101030103030103030103030101010003010101010101030101010101010101030303
0303030303030001030303030303010303030301030303030301030303030301030103030303030303030103010301030103030103010301000000000000000000000000000000000000000000000000000000000000000303030101030101030303030301030301010101010003030101010103030303010301030103030303
0000000000000001010303030301030303030303030301030101010301030303010301010101010101010301010301030303030303010301000000000000000000000000000000000000000000000000000000000000000303010303030303010303030303010101010101010003030301010303030301030301030301030303
0000000000000003010103030101010303030303030103010101010103010303010301010101010101010301010301030303030303010301000000000000000000000000000000000000000000000000000000000000000301010103030301010303030101010101010101030003030301010303030101010101010101030101
0000000000000003030101010301010103030303010303030101010303030103010303030303030303030301010301030303030303010301000000000000000000000000000000000000000000000000000000000000000301010303030303010303010303010101010303030003030301010303030303030303030303030101
0000000000000003030303030303010101030303030301010101010101030303010103010101010101030101010301030301030303010301000000000000000000000000000000000000000000000000000000000000000301010103010301010303010303010103030303030001030301010303010303030303030303030101
0000000000000003030303030303030101010303030103030101010303010303030101010303030301010103010301030303030303010301000000000000000000000000000000000000000000000000000000000000000103010101010101030103010101030303030303030303030301010101010303030303010301030303
0000000000000003030303030303030301010103010303010101010103030103010303030103030103030301010301010101010101010301000000000000000000000000000000000000000000000000000000000000000103030101010303030100030101010101010101030303030301010101010103030303030303030101
0000000000000003030303030303030303010103030301030101010301030303010101030103030103010101010303030303030303030301000000000000000000000000000000000000000000000000000000000000000101010303030301010100010303030303030303010301010301010101010103030303030303030101
0000000000000003030303030101010303030303030301030301030301030303010301030101010103010301030301010101010101010101000000000000000000000000000000000000000000000000000000000000000303030301010303030303010303030303030303010301010301010101010101010101010101030101
0000000000000003030303010103010303030303030301030303030301030303010303030303030303030301030301030303030303030301000000000000000000000000000000000000000000000000000000000000000303030101010103030303010301030303010103010301010303030303010303010303010303030303
0000000000000003030303010303030101010301010101030303030303010100030103030303030303030103010301030303010301030301000000000000000000000000000000000000000000000000000000000000000303030301010303030303030301030303010103030103030303030303030103010301010103010301
0000000000000003030301010303030103010303030103030101010103030100030301030103030103010303030101030101010101030301000000000000000000000000000000000000000000000000000000000000000303010101010101030303010301030303030303010101030101010103010101030101010103010301
0000000000000001010103030303030303030103030303010101010101030300030301030103030103010303030301030301030303010301000000000000000000000000000000000000000000000000000000000000000303030101010103030303010303030303030303010101030101010301010103010301010103010301
0000000000000003030303030303030303030103010101010303030301010300010101030303030303010101010101030301030303010301000000000000000000000000000000000000000000000000000000000000000301010101010101010303010303030303030303010101030101010301010303010303010303030303
0000000000000001010103030303030303010103010301010301010301010300030303010301010301030303030301030301010101030301000000000000000000000000000000000000000000000000000000000000000303010101010101030303010303030303030303010103030303030303030303030103010301030303
0000000000000003030303030303030303010103010301010301010301010300030301030101010103010303010101030301030303010301000000000000000000000000000000000000000000000000000000000000000101010101010101010103010303030303030303010103030303030303030103030103010301030301
__sfx__
0002000021250202501b25018250112500d2500725006250042500020001200062000220002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000090500e05011050150501a0501e050250502f050380500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001a0501b0501b0501b0501b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700002d0502e05030050182001f2002f05030050320503405034050195001e00034050350503605037050245000b50008500075003c0500450003500025000f00021100201001f1000c10001100051003c100
0010000000000120001200012000130001500017000230001d000160000c000280002c00033000000001b0000f0000a000000001f000260002f0002d0000000000000170000b000090001a0001d0002d0003e000
