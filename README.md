# Demo-molecule

##  Installation

https://colab.research.google.com/drive/18czro8R85A8r6q8iZH0lExVRk6NHrvB9?hl=fr

Mount drive:
```
from google.colab import drive
drive.mount("/content/gdrive")
```

Initialize environment:
```
%cd /content/gdrive/MyDrive/
!rm -rf demo-molecule
!git clone https://github.com/christopherlouet/demo-molecule
%cd demo-molecule
!bash install_docker.sh
```
