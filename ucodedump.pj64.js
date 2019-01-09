const SP_MEM_ADDR_REG = 0xA4040000;
const SP_DRAM_ADDR_REG = 0xA4040004;
const SP_DRAM_RD_LEN_REG = 0xA4040008;

const DMEM_OFFSET_OSTASK = 0x04000FC0;

////////////////////

// http://n64devkit.square7.ch/header/sptask.htm
const OSTask_fields = {
    type:             u32,
    flags:            u32,
    ucode_boot:       u32, // u64*
    ucode_boot_size:  u32,
    ucode:            u32, // u64*
    ucode_size:       u32,
    ucode_data:       u32, // u64*
    ucode_data_size:  u32,
    dram_stack:       u32, // u64*
    dram_stack_size:  u32,
    output_buff:      u32, // u64*
    output_buff_size: u32,
    data_ptr:         u32, // u64*
    data_size:        u32,
    yield_data_ptr:   u32, // u64*
    yield_data_size:  u32,
};

const OSTask = mem.typedef(OSTask_fields);

OSTask.prototype.dumpMicrocodeBoot = function(path)
{
    dumpRamToFile(path, this.ucode_boot, this.ucode_boot_size)
}

OSTask.prototype.dumpMicrocode = function(path)
{
    var size = this.ucode_size;

    if(this.type == 1) 
    {
        size = this.calcMicrocodeSize(0x0000);
    }

    dumpRamToFile(path, this.ucode, size);
}

OSTask.prototype.dumpMicrocodeData = function(path)
{
    dumpRamToFile(path, this.ucode_data, this.ucode_data_size);
}

OSTask.prototype.dumpData = function(path) // alist, dlist
{
    dumpRamToFile(path, this.data_ptr, this.data_size);
}

OSTask.prototype.log = function()
{
    var fields = Object.keys(OSTask_fields);
    
    var taskStr = "";

    for(var i in fields)
    {
        var field = fields[i];
        var fieldStr = field;
        var valueStr = "0x" + this[field].hex();
        
        while(fieldStr.length < 18)
        {
            fieldStr = fieldStr + " ";
        }

        taskStr += fieldStr + valueStr + "\r\n";
    }

    console.log(taskStr);
}

OSTask.prototype.calcMicrocodeSize = function(overlayEntriesOffset)
{
    var totalSize = 0;
    var vAddrOverlayEntries = ptov(this.ucode_data + overlayEntriesOffset);

    // assume 5 entries
    var vAddrLastOverlayEntry = vAddrOverlayEntries + (4 * 8);

    var offset = mem.u32[vAddrLastOverlayEntry + 0x00];
    var size = mem.u16[vAddrLastOverlayEntry + 0x04] + 1;

    return offset + size;
}

var gameName = rom.getstring(0x20).trim();
console.log(gameName);

var ucodeDumpDir = 'ucode_dumps'
var ucodeDumpGameDir = ucodeDumpDir + '/' + gameName;

fs.mkdir(ucodeDumpDir);
fs.mkdir(ucodeDumpGameDir);

var spMemAddr;
var spDramAddr;

// have to do this because SP_MEM_ADDR_REG and SP_DRAM_ADDR_REG are technically write-only
events.onwrite(SP_MEM_ADDR_REG, function(addr){ spMemAddr = getStoreWordValue(); });
events.onwrite(SP_DRAM_ADDR_REG, function(addr){ spDramAddr = getStoreWordValue(); });

events.onwrite(SP_DRAM_RD_LEN_REG, function(addr)
{
    if(spMemAddr != DMEM_OFFSET_OSTASK)
    {
        return;
    }

    var osTaskVAddr = 0x80000000 | spDramAddr;
    var osTask = new OSTask(osTaskVAddr);

    switch(osTask.type)
    {
    case 1: OnRspGfxTask(osTask); break;
    case 2: OnRspAudioTask(osTask); break;
    }
})

var audioDumped = false;
var gfxDumped = false;
var bootDumped = false;

/*

note: right now these functions only dump the first ucode they encounter,
      so they won't work properly for games that use multiple microcodes

todo generate crc32 of ucode and push to an array to keep track of what's been dumped

*/

function OnRspAudioTask(osTask)
{
    if(!audioDumped)
    {
        console.log("rsp received audio task");
        osTask.log();
        osTask.dumpMicrocode(ucodeDumpGameDir + "/audio_ucode.bin");
        osTask.dumpMicrocodeData(ucodeDumpGameDir + "/audio_ucode_data.bin");
        audioDumped = true;
    }

    if(!bootDumped)
    {
        osTask.dumpMicrocodeBoot(ucodeDumpGameDir + "/ucode_boot.bin");
        bootDumped = true;
    }
}

function OnRspGfxTask(osTask)
{
    if(!gfxDumped)
    {
        console.log("rsp received gfx task");
        osTask.log();
        osTask.dumpMicrocode(ucodeDumpGameDir + "/gfx_ucode.bin");
        osTask.dumpMicrocodeData(ucodeDumpGameDir + "/gfx_ucode_data.bin");
        gfxDumped = true;
    }

    if(!bootDumped)
    {
        osTask.dumpMicrocodeBoot(ucodeDumpGameDir + "/ucode_boot.bin");
        bootDumped = true;
    }
}

////////////////////

function dumpRamToFile(path, pAddr, size)
{
    var vAddr = ptov(vAddr);
    var data = mem.getblock(vAddr, size);
    fs.writeFile(path, data);
}

// get SW command's value to be stored
function getStoreWordValue()
{
    var opcode = mem.u32[gpr.pc];
    var rt = (opcode >> 16) & 0x1F;
    var value = gpr[rt];
    return value;
}

function ptov(pAddr)
{
    return (0x80000000 | pAddr) >>> 0;
}