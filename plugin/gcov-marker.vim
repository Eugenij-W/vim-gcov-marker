function! SetCov(...)
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
   exe ":sign define gcov_covered linehl=GcovCovered text=✓"
   exe ":sign define gcov_uncovered linehl=GcovUncovered text=✘"
   for line in readfile(filename)
      if line =~ ':'
         let d = split(line, ':')
         let c = substitute(d[0], " *", "", "")
         let l = substitute(d[1], " *", "", "")
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
   exe ":lopen"
endfunction

" Generate and load gcov
function! LoadDir(...)
   if(a:0 == 2)
         let dirname = a:2
   elseif (a:0 == 1)
      if(a:1 == '!')
         exe ":sign unplace *"
         return
      endif
      if(exists("b:coveragedir") && b:coveragedir != '')
         let dirname = b:coveragedir
      else
         echoerr "no dir for buffer specified yet"
         return
      endif
   else
      return
   endif

   let b:coveragedir = dirname
   let filename = expand('%:t')
   " Generate gcov
   silent exe ":!pushd " . dirname . "; gcov " . filename . ";popd" | redraw!

   "Load the new gcov file
   call SetCov('<bang>', dirname . '/' . filename . ".gcov")
endfunction

command! -bang -nargs=* -complete=file GcovLoad call SetCov('<bang>',<f-args>)
command! -bang -nargs=* -complete=dir GcovLoadDir call LoadDir('<bang>',<f-args>)

