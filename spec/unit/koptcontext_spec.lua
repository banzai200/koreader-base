local ffi = require("ffi")
local KOPTContext = require("ffi/koptcontext")
local mupdf = require("ffi/mupdf")
local k2pdfopt = ffi.load("libs/libk2pdfopt.so.2")

local sample_pdf = "spec/base/unit/data/Alice.pdf"
local paper_pdf = "spec/base/unit/data/Paper.pdf"

describe("KOPTContext module", function()
	it("should be created", function()
		local kc = KOPTContext.new()
		assert.is_not_nil(kc)
	end)
	describe("set/get API", function()
		it("should set/get wrap", function()
			local kc = KOPTContext.new()
			for wrap = 0, 1 do
				kc:setWrap(wrap)
				assert.equals(kc:getWrap(), wrap)
			end
		end)
		it("should set/get trim", function()
			local kc = KOPTContext.new()
			for trim = 0, 1 do
				kc:setTrim(trim)
				assert.equals(kc:getTrim(), trim)
			end
		end)
		it("should set/get zoom", function()
			local kc = KOPTContext.new()
			for zoom = 0.2, 2.0, 0.2 do
				kc:setZoom(zoom)
				assert.equals(kc:getZoom(), zoom)
			end
		end)
		it("should set/get BBox", function()
			local kc = KOPTContext.new()
			local bbox = {10, 20, 500, 400}
			kc:setBBox(unpack(bbox))
			assert.are.same({kc:getBBox()}, bbox)
		end)
		it("should set/get language", function()
			local kc = KOPTContext.new()
			local lang = "eng"
			kc:setLanguage(lang)
			assert.are.same(kc:getLanguage(), lang)
		end)
	end)
	it("should copy bmp from other context", function()
		local kc1 = KOPTContext.new()
		assert.are.same({kc1.dst.width, kc1.dst.height}, {0, 0})
		local kc2 = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(1):toBmp(kc2.dst, 300)
		kc1:copyDestBMP(kc2)
		assert.are_not.same({kc1.dst.width, kc1.dst.height}, {0, 0})
		assert.are.same({kc1.dst.width, kc1.dst.height}, {kc2.dst.width, kc2.dst.height})
	end)
	it("should be used as reflowing context", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(2):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		assert(kc.dst.size_allocated ~= 0)
		assert.are_not.same({kc.dst.width, kc.dst.height}, {0, 0})
	end)
	it("should get larger reflowed page with larger original page", function()
		local kc1 = KOPTContext.new()
		local kc2 = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(2):toBmp(kc1.src, 167)
        mupdf.openDocument(sample_pdf):openPage(2):toBmp(kc2.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc1)
		k2pdfopt.k2pdfopt_reflow_bmp(kc2)
		assert(kc1.dst.height < kc2.dst.height)
	end)
	it("should get reflowed word boxes", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(3):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local boxes = kc:getReflowedWordBoxes("dst", 0, 0, kc.dst.width, kc.dst.height)
		for i = 1, #boxes do
			for j = 1, #boxes[i] do
				local box = boxes[i][j]
				assert.are_not_nil(box.x0, box.y0, box.x1, box.y1)
			end
		end
	end)
	it("should get native word boxes", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(4):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local boxes = kc:getNativeWordBoxes("dst", 0, 0, kc.dst.width, kc.dst.height)
		for i = 1, #boxes do
			for j = 1, #boxes[i] do
				local box = boxes[i][j]
				assert.are_not_nil(box.x0, box.y0, box.x1, box.y1)
			end
		end
	end)
	it("should transform native postion to reflowed position", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(5):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		for j = 0, 800, 100 do
			for i = 0, 600, 100 do
				local x, y = kc:nativeToReflowPosTransform(i, j)
				assert.are_not_nil(x, y)
			end
		end
	end)
	it("should transform reflow postion to native position", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(5):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		for j = 0, 800, 100 do
			for i = 0, 600, 100 do
				local x, y = kc:reflowToNativePosTransform(i, j, 0.5, 0.5)
				assert.are_not_nil(x, y)
			end
		end
	end)
	it("should get OCR word from tesseract OCR engine", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(5):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local word = kc:getTOCRWord("dst", 280, 40, 100, 40, "data", "eng", 3, 0, 0)
		assert.are_same(word, "Alice")
		kc:freeOCR()
	end)
	it("should free dst bitmap after reflowing", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(6):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		assert(kc.dst.size_allocated ~= 0)
		kc:free()
		assert(kc.dst.size_allocated == 0)
	end)
	it("should get list of page regions", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(1):toBmp(kc.src, 300)
		kc.page_width, kc.page_height = kc.src.width, kc.src.height
		local regions = kc:getPageRegions()
		for i = 1, #regions do
			assert(regions[i].x1 - regions[i].x0 <= 1)
			assert(regions[i].y1 - regions[i].y0 <= 1)
		end
	end)
	it("should convert koptcontext to/from table", function()
		local kc = KOPTContext.new()
		kc:setLanguage("eng")
        mupdf.openDocument(sample_pdf):openPage(6):toBmp(kc.src, 300)
		k2pdfopt.k2pdfopt_reflow_bmp(kc)
		local kc_table = KOPTContext.totable(kc)
		local new_kc = KOPTContext.fromtable(kc_table)
		local new_kc_table = KOPTContext.totable(new_kc)
		assert.are.same(kc_table.bbox, new_kc_table.bbox)
		assert.are.same(kc_table.language, new_kc_table.language)
		assert.are.same(kc_table.dst_data, new_kc_table.dst_data)
		assert.are.same(kc_table.src_data, new_kc_table.src_data)
		assert.are.same(kc_table.rboxa, new_kc_table.rboxa)
		assert.are.same(kc_table.rnai, new_kc_table.rnai)
		assert.are.same(kc_table.nboxa, new_kc_table.nboxa)
		assert.are.same(kc_table.nnai, new_kc_table.nnai)
		assert.are.same(kc_table.rectmaps, new_kc_table.rectmaps)
		kc:free()
		new_kc:free()
	end)
    it("should export src bitmap to PNG file", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(1):toBmp(kc.src, 300)
		kc:exportSrcPNGFile(nil, nil, "/tmp/src.png")
    end)
    it("should export src bitmap to PNG string", function()
		local kc = KOPTContext.new()
        mupdf.openDocument(sample_pdf):openPage(1):toBmp(kc.src, 300)
		local png = kc:exportSrcPNGString("none")
        assert.truthy(png)
    end)
end)
