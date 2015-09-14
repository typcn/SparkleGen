SparkleGen
-----------
Generate Sparkle appcast.xml / delta patches and sign it automaticly ( Experimental )

![img](http://img0.eqoe.cn/FtAgRyYFoHs76zDNyjV89EfpMvSQ)


## Build

```Bash
git clone https://github.com/typcn/SparkleGen.git
git submodule update --init
open *.xcodeproj
```
## Usage

1. Select private key & BinaryDelta executable location ( only once , save automatically )
2. Drag & Drop your ".app" file.
3. Click Generate , and open "update_xxx" folder

You can set "Publish" action in ViewController.m , integration with S3 SDK , CDN API or SFTP to upload it.

## License

MIT