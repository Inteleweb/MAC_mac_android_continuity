adb shell dumpsys display | awk '
/DisplayDeviceInfo/ {device=$0}
/DisplayDeviceInfo.*id=/ {match($0,/id=[0-9]+/,a); id=a[0]; sub("id=","",id)}
/DisplayDeviceInfo.*name=/ {match($0,/name=[^,]*/,b); name=b[0]; sub("name=","",name)}
/mCurrentState=/ {match($0,/mCurrentState=[^,]*/,c); state=c[0]; sub("mCurrentState=","",state)}
/mBaseDisplayInfo/ {
  match($0,/width=[0-9]+/,w); match($0,/height=[0-9]+/,h);
  width=w[0]; height=h[0]; sub("width=","",width); sub("height=","",height);
  printf("ID: %s | Name: %s | State: %s | Resolution: %sx%s\n", id, name, state, width, height);
}'
