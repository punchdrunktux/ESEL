#!/bin/sh

check_services(){
  # If the curl operation fails, we'll just leave the variable equal to 0;  1 means everything is good
  echo "-------------------------------------------------------------------------"
  echo "------ Checking to see if Control Tower services are functioning --------"
  echo "-------------------------------------------------------------------------"
  CALDERA_CHECK=$(curl -ks -m 2 http://192.168.38.10:8888/login | grep -c 'access' || echo "")
  if ["$CALDERA_CHECK" -lt 1]; then
    echo "Warning: Caldera may not be functioning correctly"
  else
    echo "Success!  Caldera is running at http://192.168.38.10:8888/"
  fi

  COVENANT_CHECK=$(curl -ks -m 2 https://192.168.38.10:7443/ | grep -c 'access' || echo "")
  if ["$CALDERA_CHECK" -lt 1]; then
    echo "Warning: CovenantC2 may not be functioning correctly"
  else
    echo "Success!  CovenantC2 is running at https://192.168.38.10:7443/"
  fi
}

check_services
exit 0
