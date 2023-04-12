# 在超算集群上安装Enviroment Modules

一个简易的超算集群（我也没弄过超大集群）通常由一个管理节点和一些计算节点组成。大部分的软件和库都安装在管理节点上，而计算节点一般只需要安装基本的软件就好了。

一般我们将管理节点上的某个文件夹通过nfs服务分享给计算节点，这里假定为`/opt`文件夹。（nfs服务的配置就不赘述了，网上有很多资料。）注意计算节点挂载这个共享文件夹的路径也要是`/opt`，这样才好统一配置。

我们的目标是把所有的软件和库都安装在管理节点的`/opt`文件夹下，从而计算节点也自动获取了这些软件和库。所以，超算上的软件最好是源代码安装，不要用包管理器。不过，各个系统最好还是统一系统，并用包管理器统一安装一次`gcc`，毕竟连`gcc`都没有实在寸步难行。

这样安装的好处除了方便，不用做重复劳动之外，还避免了不同的节点安装的软件配置有差别，可能会出问题。

> 以下的安装以Debian为例，其他系统可能会有不同。

## Modules安装

当然，Modules也需要安装在管理节点的`/opt`文件夹下。从[Modules 官网](https://modules.sourceforge.net/)下载最新的源代码。

Modules依赖于`tcl`，所以需要在每个节点安装（因为以后需要在每个节点上运行Modules）
```bash
apt install tcl-dev
```

然后编译源代码
```bash
tar -xzvf modules-5.2.0.tar.gz
cd modules-5.2.0
./configure --prefix=/opt/modules/
make
make install
```

### 配置Modules的路径

Modules是用于给软件和库配置路径的，但是在这之前要给它自己配置路径。上述安装完成之后，在每一个节点使用命令
```bash
ln -s /opt/modules/init/profile.sh /etc/profile.d/modules.sh
```
这个`init/profile.sh`是Modules给你写好的配置路径的脚本，把他链接到自动运行文件夹`/etc/profile.d/`里面，就完成了配置。

注意必须在每个节点都要做上述链接。并且，我们后面可能会修改`init/profile.sh`文件，所以最好使用链接而不是复制。

## 配置`modulefile`文件夹

Modules使用modulefile文件来配置某个软件的路径，一般把我们的一些modulefile放在某个文件夹下，然后使用
```bash
module use module-file-dir
```
来使用这个文件夹下的的modulefile。为了使其永久生效，可以将其写到`init/profile.sh`里面去。

比如，安装[Intel oneAPI](https://www.intel.cn/content/www/cn/zh/developer/tools/oneapi/toolkits.html)，它的默认路径一般是`/opt/intel/oneapi/`，而安装完成之后，通过运行`modulefiles-setup.sh`就会自动生成一大堆modulefile，在文件夹`/opt/intel/oneapi/modulefiles`下。于是你可以在`init/profile.sh`脚本最后面添加
```bash
module use /opt/intel/oneapi/modulefiles
```
### 编写`modulefile`

对于我们自己手动安装的软件和库，需要手写`modulefile`，一个例子如下
```tcl
#%Module -*- tcl -*-

proc ModulesHelp {} {
        puts stderr "arpack-ng-3.9.0, compiled with gcc-10.2.1"
}

module-whatis "arpack-ng-3.11.0, compiled with gcc-10.2.1"

# load其他模块
module load lapack/3.11.0

# 这里的变量其实和`bash`里面变量是一致的，比如还有`PATH`设置可执行文件路径
prepend-path LD_LIBRARY_PATH    /opt/library/arpack-ng-3.9.0/lib
prepend-path C_INCLUDE_PATH     /opt/library/arpack-ng-3.9.0/include
prepend-path CPLUS_INCLUDE_PATH /opt/library/arpack-ng-3.9.0/include
prepend-path PKG_CONFIG_PATH    /opt/library/arpack-ng-3.9.0/lib/pkgconfig
```
更详细的请看文档吧：[Eiviroment Modules文档：modulefile](https://modules.readthedocs.io/en/latest/modulefile.html)。

以上是针对管理员的安装知识。

##  用户的使用指导

超算的用户只需要知道以下知识。

使用`module`系列命令来引入库。其中

* `module avail`查看可以被引入的库；
* `module load xxx`，引入某库。例如，`module load compiler/2023.0.0`引入intel的编译器组件；
* `module list`，查看你当前引入了哪些库；
* `module unload xxx`，取消引入某库；
* `module purge`，清空你引入的所有库

尽管书写正确的modulefile防止冲突是管理员的事情，但是用户最好也不要同时`load`某个软件的不同版本。

在使用slurm提交作业时，为了保证在计算节点上的软件环境配制是正确的，你可以有两个选择。你可以使用
```bash
#SBATCH --get-user-env
```
来获取当前的环境；或者直接在提交脚本里面写好`module load xxx`。
