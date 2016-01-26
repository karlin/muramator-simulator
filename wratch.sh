while [ true ]; do
  sleep 2
  if [ muramator.coffee -nt muramator.js ]; then
    coffee -c muramator.coffee && echo '.'
  fi
done
