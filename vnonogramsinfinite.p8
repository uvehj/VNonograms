pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
puzzle = {}
state = 0
cursorpos = {0,0}
selectedsize = {7,5}
function _init()
    state = 0
end
function _draw()
    cls(7)
    if state == 1 then
        draw_instructions()
        draw_board(puzzle.x,puzzle.y)
    elseif state == 2 then
        draw_board(puzzle.x,puzzle.y)
        draw_win()
    elseif state == 0 then
        draw_title()
    elseif state == -1 then
        draw_creation_error()
    end
end
function _update60()
    if state == -1 then
        update_buttons_error()
        state = create_puzzle(selectedsize)
    elseif state == 1 then
        update_buttons_game()
        state = check_finished_and_autocomplete()
    elseif state == 0 then
        update_buttons_menu()
    elseif state == 2 then
        update_buttons_finish()
    end
end

function create_puzzle(size)
    puzzle.width = size[1]
    puzzle.height = size[2]
    puzzle.mistakes=0
    puzzle.board = {}
    local x = 1
    local y = 1
    while x <= puzzle.width do
        y = 1
        local row = {}
        while y <= puzzle.height do
            --solution,uncovered,failed
            add(row,{flr(rnd(2)),0,0})
            y += 1
        end
        add(puzzle.board,row)
        x += 1
    end
    puzzle.longestrow = 0
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
        add(puzzle.rownumbers,currow)
        puzzle.longestrow = max(puzzle.longestrow, #currow)
        y += 1
    end
    i = 1
    puzzle.longestcolumn = 0
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
        add(puzzle.columnnumbers,curcolumn)
        puzzle.longestcolumn = max(puzzle.longestcolumn,#curcolumn)
        x += 1
    end
    --local ynum = puzzle.y - 1 - #column * 6
    --local xnum = puzzle.x - #row * 6
    puzzle.pixelsize = {puzzle.longestrow*6+puzzle.width*8,1+puzzle.longestcolumn+puzzle.height*8}
    puzzle.x = 68-(puzzle.pixelsize[1]/2)+(puzzle.longestrow*5)
    puzzle.y = 58-(puzzle.pixelsize[2]/2)+(puzzle.longestcolumn*2)

    if puzzle.pixelsize[1] > 128 or puzzle.pixelsize[2] > 100 then
        return -1
    else
        return 1
    end
end
function draw_creation_error()
    print("creating puzzle...",1,58,0)
    print("size might be too big",1,64,0)
    print("press any button to go back",1,70,0)
end
function draw_title()
    pal(7,0)
    --"nonograms" letter
    sspr(0,8,8,8,67,32,8*3,8*3,false,false)
    sspr(0,8,8,8,67+8*3,32,8*3,8*3,false,false)
    sspr(8,8,8*3,8,67,50,8*3*3,8*3,false,false)
    pal()
    --line break
    rectfill(66+8*2*3,32+5,66+8*2*3+8,32+7,0)
    --numbers for the fake nonogram
    local titlerows = {"33","11","11","11","11"," 1"}
    local y = 15
    for row in all(titlerows) do
        print(row,1,y,0)
        y += 8
    end
    print("1   1   1\n1 2 2 1 1 5 1",11,1)
    --fake nonogram
    rectfill(9,13,9+7*8,13+6*8,5)
    map(0,0,9,13,7,6)
    --subtitle
    local subtitle = {"i","n","f","i","n","i","t","e"}
    local x = 64 - #subtitle*4
    rectfill(x,70,x + #subtitle*8,78,5)
    local spriten = 0
    for letter in all(subtitle) do
        spr(1+spriten*2,x,70)
        print(letter,x+2,72,0)
        x += 8
        spriten = abs(spriten-1)
    end
    --instructions
    print("\148",80,90)
    print("width \139"..tostr(selectedsize[1]).."\145 height "..tostr(selectedsize[2]).."  start\142",4,96,0)
    print("\131",80,102)
    --credits
    print("game by uvehj",2,116,0)
    print("github.com/uvehj/vnonograms",2,122,0)
end

function draw_instructions()
    --instructions
    print("\148\131\139\145move  \142reveal  \151empty",1,122)
end

function draw_win()
    print("puzzle finished!",1,1,0)
    print("mistakes made: "..tostr(puzzle.mistakes),1,8,0)
    print("press any button",1,16,0)
end

function draw_board(posx,posy)
    --board
    rectfill(posx-1,posy-1,posx+1+puzzle.width*8,posy+1+puzzle.height*8,5)
    local x = 1
    while x <= puzzle.width do
        local y = 1
        while y <= puzzle.height do
            spr(get_tile_sprite(puzzle.board[x][y]),posx+(x-1)*8,posy+(y-1)*8)
            y += 1
        end
        x += 1
    end
    --cursor
    spr(7,posx+cursorpos[1]*8,posy+cursorpos[2]*8)
    --row numbers
    local ynum = puzzle.y + 2
    for row in all(puzzle.rownumbers) do
        local xnum = puzzle.x - #row * 6
        for number in all(row) do
            print(number,xnum,ynum,0)
            xnum += 6
            if flr(number/10) > 0 then
                xnum += 4
            end
        end
        ynum += 8
    end
    --column numbers
    local xnum = puzzle.x + 2
    for column in all(puzzle.columnnumbers) do
        local ynum = puzzle.y - 1 - #column * 6
        for number in all(column) do
            print(number,xnum,ynum,0)
            ynum += 6
        end
        xnum += 8
    end
end
function get_tile_sprite_debug(tile)
        if tile[1] == 1 then --tile was colored
            if tile[3] == 1 then --tile is failed
                return 6
            else --colored not failed
                return 3
            end
        else --tile is not colored
           if tile[3] == 1 then --tile is failed
                return 5
            else --not colored not failed
                return 2
            end         
        end
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
                return 5
            else --not colored not failed
                return 2
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
    if (btnp(4) or btnp(5)) and puzzle.board[cursorpos[1]+1][cursorpos[2]+1][2] == 0 then
        puzzle.board[cursorpos[1]+1][cursorpos[2]+1][2] = 1
        if puzzle.board[cursorpos[1]+1][cursorpos[2]+1][1] == 1 and btnp(5) then
            puzzle.board[cursorpos[1]+1][cursorpos[2]+1][3] = 1
            puzzle.mistakes += 1
            sfx(0)
        elseif puzzle.board[cursorpos[1]+1][cursorpos[2]+1][1] == 0 and btnp(4) then
            puzzle.board[cursorpos[1]+1][cursorpos[2]+1][3] = 1
            puzzle.mistakes += 1
            sfx(0)
        else
            sfx(1)
        end
    end
end

function update_buttons_menu()
    if btnp(4) then
        sfx(2)
        state = -1
    end
    if btnp(0) then
        selectedsize[1] = max(1,selectedsize[1]-1)
    elseif btnp(1) then
        selectedsize[1] += 1
    elseif btnp(2) then
        selectedsize[2] += 1
    elseif btnp(3) then
        selectedsize[2] = max(1,selectedsize[2]-1)
    end
end

function update_buttons_finish()
    if btnp(4) or btnp(5) then
        sfx(2)
        state = 0
    end
end

function update_buttons_error()
    if btnp(4) or btnp(5) then
        sfx(2)
        state = 0
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
        return 2
    else
        return 1
    end
end
__gfx__
00000000000000000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000000000000000000000000000
0000000007777770066666600cccccc007777770066666600cccccc0800000080000000000000000000000000000000000000000000000000000000000000000
0070070007777770066660600cccccc007777870068668600c8cc8c0800000080000000000000000000000000000000000000000000000000000000000000000
0007700007777770066606600cccccc007778770066886600cc88cc0800000080000000000000000000000000000000000000000000000000000000000000000
0007700007777770066066600cccccc007787770066886600cc88cc0800000080000000000000000000000000000000000000000000000000000000000000000
0070070007777770060666600cccccc007877770068668600c8cc8c0800000080000000000000000000000000000000000000000000000000000000000000000
0000000007777770066666600cccccc007777770066666600cccccc0800000080000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000000000000000000000000000
77000770077077707770777007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070700070707070777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070700077007770707077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707070707070707070707000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70707700777070707070707077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030103030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103010101030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101030101030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101030101030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010301030100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010103010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000021250202501b25018250112500d2500725006250042500020001200062000220002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000090500e05011050150501a0501e050250502f050380500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001a0501b0501b0501b0501b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700002d0502e05030050182001f2002f05030050320503405034050195001e00034050350503605037050245000b50008500075003c0500450003500025000f00021100201001f1000c10001100051003c100
0010000000000120001200012000130001500017000230001d000160000c000280002c00033000000001b0000f0000a000000001f000260002f0002d0000000000000170000b000090001a0001d0002d0003e000
