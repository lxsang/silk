TESTS = {}

function test(description, fn)
    TESTS[#TESTS + 1] = {description = description,  test = fn }
end


function run()
    local report = {
        ok = 0,
        fail= 0,
        total = #TESTS
    }
    for l,ts in ipairs(TESTS) do
        io.write(string.format("Executing: %s...",ts.description))
        local status,err = pcall(ts.test)
        if status then
            io.write("\27[32mOK\27[0m\n")
            report.ok = report.ok + 1
        else
            io.write("\27[31mFAIL\27[0m\n")
            print(err)
            report.fail = report.fail + 1
        end
    end
    print("----------------------------")
    print(string.format("Total tests: %d", report.total))
    print(string.format("Tests passed: %d", report.ok))
    print(string.format("Tests failed: %d", report.fail))
    TESTS = {}
end

function assert(b, e,...)
    if not b then
        error(string.format(e,...))
        print(debug.traceback())
    end
end

function expect(v1,v2)
    assert(v1 == v2, "Expect: [%s] get: [%s]", tostring(v2), tostring(v1))
end

function unexpect(v1,v2)
    assert(v1 ~= v2, "Unexpect value", tostring(v2))
end