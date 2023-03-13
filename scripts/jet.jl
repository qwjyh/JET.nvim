using JET

filename = only(ARGS)

function print_reports(io, result)

    reports = JET.get_reports(result)
    postprocess = JET.gen_postprocess(result.res.actual2virtual)

    JET.with_bufferring(:color => get(io, :color, false)) do io
        toplevel_linfo_hash = hash(:dummy)
        wrote_linfos = Set{UInt64}()
        for report in reports
            new_toplevel_linfo_hash = hash(first(report.vst))
            if toplevel_linfo_hash != new_toplevel_linfo_hash
                toplevel_linfo_hash = new_toplevel_linfo_hash
                wrote_linfos = Set{UInt64}()
            end
            print_report(io, report)
        end
    end |> postprocess |> (x -> print(io::IO, x))

end

function print_report(io, report::JET.InferenceErrorReport, depth=1)
    if length(report.vst) == depth # error here
        return print_error_report(io, report)
    end
    print_report(io, report, depth + 1)
end

function get_report_msg(report::JET.InferenceErrorReport)
    buf = IOBuffer()
    JET.print_report(buf, report)
    return String(take!(buf))
end

function print_error_report(io, report::JET.InferenceErrorReport)
    frame = report.vst[1]
    printstyled(io, string(frame.line), ":")
    printstyled(io, "E", ": ")
    printstyled(io, get_report_msg(report), ": "; color=JET.ERROR_COLOR)
    JET.print_signature(io, report.sig,
        (; annotate_types=true); # always annotate types for errored signatures
        bold=true
    )
    print(io, '\n')
end

function print_error_report(io, report)
    printstyled(io, report.msg, "\n"; color=JET.ERROR_COLOR)
end

r = report_file(filename, analyze_from_definitions=true)
print_reports(stderr, r)

