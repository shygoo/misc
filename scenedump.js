const RSP_DISPLAYLIST_CMD = 1;

const RSP_COMMAND_ADDR = 0xA4000FC0;
const RSP_UCODE_ENGINE_ADDR = 0xA4000FD0;
const RSP_DISPLAYLIST_ADDR = 0xA4000FF0;
const RSP_DISPLAYLIST_SIZE = 0xA4000FF4;

var evtdraw = events.ondraw(function()
{
    if(mem.u32[RSP_COMMAND_ADDR] != RSP_DISPLAYLIST_CMD)
    {
        return;
    }

    events.remove(evtdraw);

    var dlistAddr = mem.u32[RSP_DISPLAYLIST_ADDR];
    var dlistSize = mem.u32[RSP_DISPLAYLIST_SIZE];
    var ucodeEngineAddr = mem.u32[RSP_UCODE_ENGINE_ADDR];

    var buf = mem.getblock(0x80000000, 0x400000);
    var u8arr = new Uint8Array(buf);

    var dv = new DataView(u8arr.buffer);
    dv.setUint32(0x00, dlistAddr);
    dv.setUint32(0x04, ucodeEngineAddr);

    var fd = fs.open('data.bin', 'wb')
    fs.write(fd, u8arr.buffer)
    fs.close(fd)

    console.log('ok')
});