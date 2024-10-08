if exists('g:autoloaded_gcov_marker') || &cp || version < 700
    finish
else
    if !exists("g:gcov_marker_covered")
        let g:gcov_marker_covered = '✓'
    endif
    if !exists("g:gcov_marker_uncovered")
        let g:gcov_marker_uncovered = '✘'
    endif
    if !exists("g:gcov_marker_auto_lopen")
        let g:gcov_marker_auto_lopen = 1
    endif
    if !exists("g:gcov_marker_path")
        let g:gcov_marker_path = '.'
    endif
endif

function gcov_marker#FindCov(...)
    if (a:0 == 1)
        if(a:1 == '!')
            exe ":sign unplace *"
            return
        endif
    endif
    let filename = expand('%:t')
    let files = split(globpath(g:gcov_marker_path, filename . ".gcov"), '\n')
    if (len(files) == 0)
        echoerr "could not find any file named " . filename . ".gcov"
        return
    endif
    " check current file name matches Source
    for file in files
        for line in readfile(file)
            if line =~ '\V:.*:.*:'
                let d = split(line, ':')
                let c = substitute(d[0], " *", "", "")
                let l = substitute(d[1], " *", "", "")
                if c == '-' && l == 0 && d[2] =~ "Source" && d[3] == expand('%:p')
                    echo "load file " . file . " for coverage"
                    call gcov_marker#SetCov('<bang>', file)
                    return
                endif
            endif
        endfor
    endfor
  endfunction

function gcov_marker#SetCov(...)
    if(a:0 == 2)
        let filename = a:2
    elseif (a:0 == 1)
        if(a:1 == '!')
            exe ":sign unplace *"
            return
        endif
        if(exists("b:coveragefile") && b:coveragefile != '')
            let filename = b:coveragefile
        else
            echoerr "no file for buffer specified yet"
            return
        endif
    else
        return
    endif
    "Clear previous markers
    exe ":sign unplace *"
    call setloclist(0, [])
    let currentfile = expand('%')
    "Read coverage file (work only without branch coverage at the moment )
    exe ":sign define gcov_covered linehl=GcovCoveredLine texthl=GcovCoveredText text=" . g:gcov_marker_covered
    exe ":sign define gcov_uncovered linehl=GcovUncoveredLine texthl=GcovUncoveredText text=" . g:gcov_marker_uncovered
    for line in readfile(filename)
        if line =~ ':'
            let d = split(line, ':')
            let c = substitute(d[0], " *", "", "")
            let l = substitute(d[1], " *", "", "")
            echom "l:" . l
            if '-' != c && c !~ '#' && c !~ '='
                exe ":sign place " . l . " line=" . l . " name=gcov_covered file=" . expand("%:p")
            elseif c =~ '#' || c =~ '='
                exe ":sign place " . l . " line=" . l . " name=gcov_uncovered file=" . expand("%:p")
                exe ":laddexpr '".currentfile.":".l.":uncovered'"
            endif
        endif
    endfor
    " Set the coverage file for the current buffer
    let b:coveragefile = fnamemodify(filename, ':p')
    if g:gcov_marker_auto_lopen == 1
        exe ":lopen"
    endif
endfunction

let g:autoloaded_gcov_marker = 1
