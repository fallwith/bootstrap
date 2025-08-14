function killrails --description 'Kill all rails master and worker processes'
  ps auwx | grep -E 'rails (master|worker)' | awk '{ print $2 }' | xargs -I {} kill -9 {}
end