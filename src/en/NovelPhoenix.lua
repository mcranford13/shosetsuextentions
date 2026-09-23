-- {"id":2986023,"ver":"1.0.0","libVer":"1.0.0","author":"Cursor"}

local baseURL = "https://novelphoenix.com"

local function trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function escapeHTML(value)
    return tostring(value or "")
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function encodeURL(value)
    return tostring(value or ""):gsub("([^%w%-_%.~])", function(char)
        return string.format("%%%02X", string.byte(char))
    end)
end

local function shrinkURL(url)
    return tostring(url or "")
        :gsub("^https?://[^/]+", "")
        :gsub("^/+", "")
end

local function expandURL(url)
    url = tostring(url or "")
    if url:match("^https?://") then
        return url
    end
    return baseURL .. "/" .. url:gsub("^/+", "")
end

local function imageURL(element)
    if not element then return "" end
    local image = element:selectFirst("img")
    if not image then return "" end

    local source = image:attr("data-src")
    if not source or source == "" then source = image:attr("src") end
    if not source or source == "" then return "" end
    return expandURL(source)
end

local function novelFromElement(element)
    local link = element
    if element:tagName() ~= "a" then
        link = element:selectFirst("a[href^='/novel/'], a[href*='novelphoenix.com/novel/']")
    end
    if not link then return nil end

    local href = link:attr("href")
    if not href or href == "" or href:find("/chapter", 1, true) then return nil end

    local titleElement = element:selectFirst(".novel-title")
        or element:selectFirst("h2, h3, h4")
        or link:selectFirst(".novel-title")
    local title = trim(titleElement and titleElement:text() or link:attr("title"))
    if title == "" then title = trim(link:text()) end
    if title == "" then return nil end

    local novelLink = shrinkURL(href)
    return Novel {
        title = title,
        imageURL = imageURL(element),
        link = novelLink
    }, novelLink
end

local function parseNovelList(document)
    local novels = {}
    local seen = {}
    local items = document:select(".novel-list .novel-item")

    if items:size() == 0 then
        items = document:select(".novel-item")
    end
    if items:size() == 0 then
        items = document:select("a[href^='/novel/']")
    end

    for i = 0, items:size() - 1 do
        local novel, novelLink = novelFromElement(items:get(i))
        if novel and not seen[novelLink] then
            seen[novelLink] = true
            novels[#novels + 1] = novel
        end
    end
    return novels
end

local function parseListing(path, page)
    local separator = path:find("?", 1, true) and "&" or "?"
    return parseNovelList(GETDocument(baseURL .. path .. separator .. "page=" .. page))
end

local function listing(name, path)
    return Listing(name, true, function(data)
        return parseListing(path, data[PAGE])
    end)
end

local function search(data)
    local path = "/search?keyword=" .. encodeURL(data[QUERY])
    return parseListing(path, data[PAGE])
end

local function textList(elements)
    local result = {}
    for i = 0, elements:size() - 1 do
        local value = trim(elements:get(i):text())
        if value ~= "" then result[#result + 1] = value end
    end
    return result
end

local function chapterFromElement(element, order)
    local titleElement = element:selectFirst(".chapter-title")
    local title = trim(titleElement and titleElement:text() or element:attr("title"))
    if title == "" then title = trim(element:text()) end

    local releaseElement = element:selectFirst("time, .chapter-update, .chapter-time")
    return NovelChapter {
        order = order,
        title = title,
        release = trim(releaseElement and releaseElement:text() or ""),
        link = shrinkURL(element:attr("href"))
    }
end

local function appendChapters(chapters, chapterDocument)
    local links = chapterDocument:select("ul.chapter-list li a[href]")
    for i = 0, links:size() - 1 do
        chapters[#chapters + 1] = chapterFromElement(links:get(i), #chapters + 1)
    end
end

local function findLastChapterPage(document)
    local maxPage = 1
    local links = document:select("ul.pagination a[href], .pagination-container a[href]")
    for i = 0, links:size() - 1 do
        local href = links:get(i):attr("href") or ""
        local page = tonumber(href:match("[?&]page=(%d+)") or href:match("page%-(%d+)"))
        if page and page > maxPage then maxPage = page end
    end
    return maxPage
end

local function statusFrom(document)
    local statusElement = document:selectFirst(
        ".novel-info .status, .header-stats .status, [itemprop='status']"
    )
    local status = trim(statusElement and statusElement:text() or "")
    if status == "" then
        status = document:text():match("[Ss]tatus:%s*([%a]+)") or ""
    end
    status = status:lower()
    if status:find("ongoing", 1, true) or status:find("publishing", 1, true) then
        return NovelStatus.PUBLISHING
    elseif status:find("complete", 1, true) then
        return NovelStatus.COMPLETED
    end
    return NovelStatus.UNKNOWN
end

local function parseNovel(novelURL, loadChapters)
    local novelPath = shrinkURL(novelURL)
    local document = GETDocument(expandURL(novelPath))

    local titleElement = document:selectFirst("article#novel .novel-title, h1.novel-title")
        or document:selectFirst("h1")
    local summary = document:selectFirst("article#novel .summary .content, .summary .content")
    local cover = document:selectFirst("article#novel figure.cover, .glass-background, .header-body")
    local author = document:selectFirst("article#novel span[itemprop='author'], span[itemprop='author']")
    local genres = textList(document:select(
        "article#novel .categories a[href], .categories a[href*='/genre-']"
    ))

    local chapters = {}
    local chapterDocument = nil
    if loadChapters then
        local chapterURL = expandURL(novelPath:gsub("/+$", "") .. "/chapters")
        chapterDocument = GETDocument(chapterURL)
        appendChapters(chapters, chapterDocument)

        local lastPage = findLastChapterPage(chapterDocument)
        for page = 2, lastPage do
            appendChapters(chapters, GETDocument(chapterURL .. "?page=" .. page))
        end
    end

    local info = NovelInfo {
        title = trim(titleElement and titleElement:text() or ""),
        description = trim(summary and summary:text() or ""),
        imageURL = imageURL(cover),
        authors = author and { trim(author:text()) } or {},
        genres = genres,
        status = statusFrom(chapterDocument or document)
    }
    if loadChapters then info:setChapters(AsList(chapters)) end
    return info
end

local function getPassage(chapterURL)
    local document = GETDocument(expandURL(chapterURL))
    local content = document:selectFirst("div#content, div.chapter-content")
    if not content then error("Novel Phoenix chapter content was not found") end

    content:select("script, iframe, .adsbox, .ad-container, .ad, .OUTBRAIN"):remove()
    local watermarks = content:select("p[class]")
    if watermarks:size() > 0 then watermarks:remove() end

    local titleElement = document:selectFirst("span.chapter-title")
    local title = trim(titleElement and titleElement:text() or "")
    if title ~= "" then content:prepend("<h1>" .. escapeHTML(title) .. "</h1>") end
    return pageOfElem(content, true)
end

return {
    id = 2986023,
    name = "Novel Phoenix",
    baseURL = baseURL,
    imageURL = baseURL .. "/favicon.ico",
    hasCloudFlare = true,
    hasSearch = true,
    isSearchIncrementing = true,
    listings = {
        listing("Recently Updated", "/genre-all/sort-latest-release/status-all/all-novel"),
        listing("Most Popular", "/genre-all/sort-popular/status-all/all-novel"),
        listing("Recently Added", "/genre-all/sort-new/status-all/all-novel"),
        listing("Completed", "/genre-all/sort-latest-release/status-completed/all-novel")
    },
    search = search,
    parseNovel = parseNovel,
    getPassage = getPassage,
    chapterType = ChapterType.HTML,
    shrinkURL = shrinkURL,
    expandURL = expandURL
}
