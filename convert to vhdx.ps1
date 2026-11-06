Convert-VHD -Path c:\test\testvhd.vhd -DestinationPath c:\test\testvhdx.vhdx




VBoxManage.exe" clonehd --format vhdx "D:\<INSERT DATA> CAD VM.ova" "disk001.vhdx"




	
qemu-img.exe convert "D:\<INSERT DATA> CAD VM.ova" -O vhdx -o subformat=dynamic "D:\<INSERT DATA> CAD VM.vhdx"