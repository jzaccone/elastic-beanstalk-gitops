          for d in */ ; do
            git diff --quiet HEAD~1 HEAD -- $d
            if [ $? -eq 0 ] 
            then
              echo $d changes: no 
            else
              echo $d changes: yes  
            fi
          done
