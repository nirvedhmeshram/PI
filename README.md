- [PI](#PI)
- [Installing](#installing)
- [Torch-MLIR](#torch-mlir)

<p align="center">
    <img width="598" alt="image" src="https://user-images.githubusercontent.com/5657668/205545845-544fe701-79d5-43c1-beec-09763f22cc85.png">
</p>

# PI

Early days of a lightweight MLIR Python frontend with support for PyTorch (through [Torch-MLIR](https://github.com/llvm/torch-mlir) but without a true dependency on PyTorch itself).

# Installing

Just 

```shell
pip install - requirements.txt 
pip install . -v
```

and you're good to go.

# PyTorch

[examples/minimal.py](examples/minimal.py) lowers

```python
class MyConv2d(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv = nn.Conv2d(3, 1, 3)

    def forward(self, x):
        y = self.conv(x)
        z = y + y
        w = z * z
        return w
```

to

```mlir
module attributes {pi.module_name = "MyConv2d"} {
  func.func @forward(%arg0: !torch.vtensor<[?,?,?,?],f32>) -> !torch.vtensor<[?,1,?,?],f32> {
    %false = torch.constant.bool false
    %none = torch.constant.none
    %int3 = torch.constant.int 3
    %int0 = torch.constant.int 0
    %int1 = torch.constant.int 1
    %0 = torch.prim.ListConstruct %int1 : (!torch.int) -> !torch.list<int>
    %1 = torch.aten.empty.memory_format %0, %none, %none, %none, %none, %none : !torch.list<int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[1],f32>
    %2 = torch.prim.ListConstruct %int1, %int3, %int3, %int3 : (!torch.int, !torch.int, !torch.int, !torch.int) -> !torch.list<int>
    %3 = torch.aten.empty.memory_format %2, %none, %none, %none, %none, %none : !torch.list<int>, !torch.none, !torch.none, !torch.none, !torch.none, !torch.none -> !torch.vtensor<[1,3,3,3],f32>
    %4 = torch.prim.ListConstruct %int1, %int1 : (!torch.int, !torch.int) -> !torch.list<int>
    %5 = torch.prim.ListConstruct %int0, %int0 : (!torch.int, !torch.int) -> !torch.list<int>
    %6 = torch.prim.ListConstruct  : () -> !torch.list<int>
    %7 = torch.aten.convolution %arg0, %3, %1, %4, %5, %4, %false, %6, %int1 : 
        !torch.vtensor<[?,?,?,?],f32>, 
        !torch.vtensor<[1,3,3,3],f32>, 
        !torch.vtensor<[1],f32>, 
        !torch.list<int>, 
        !torch.list<int>, 
        !torch.list<int>, 
        !torch.bool, 
        !torch.list<int>, 
        !torch.int -> !torch.vtensor<[?,1,?,?],f32>
    %8 = torch.aten.add.Tensor %7, %7, %int1 : !torch.vtensor<[?,1,?,?],f32>, !torch.vtensor<[?,1,?,?],f32>, !torch.int -> !torch.vtensor<[?,1,?,?],f32>
    %9 = torch.aten.mul.Tensor %8, %8 : !torch.vtensor<[?,1,?,?],f32>, !torch.vtensor<[?,1,?,?],f32> -> !torch.vtensor<[?,1,?,?],f32>
    return %9 : !torch.vtensor<[?,1,?,?],f32>
  }
}
```

In addition, we have several full end-to-end model examples, including [ResNet18](examples/resnet.py), [InceptionV3](examples/inception.py), [MobileNetV3](examples/mobilenet.py).

In general, PI is very alpha; to get a rough idea of the current status check the [latest tests](https://github.com/nod-ai/PI/actions?query=workflow%3ATest++).

Currently, we're passing ~650 out of 786 of Torch-MLIR's test-suite (`torch-mlir==20230127.731`).

# Development

Spin up a venv (or conda environment) with `pip install -r requirements.txt ` and configure CMake with

```shell
cmake \
    -DCMAKE_INSTALL_PREFIX=$PI_SRC_DIR/pi \
    -DPython3_EXECUTABLE=$(which python) \
    -S $PI_SRC_DIR \
    -B $PI_BUILD_DIR
```

where `$PI_SRC_DIR` is the path to the checkout of this repo and `$PI_BUILD_DIR` is where you want to build into. Then

```shell
cmake --build $PI_BUILD_DIR --target install
```

which will install `_mlir_libs`, `dialects`, and `runtime` underneath `$PI_SRC_DIR/mlir`.
Then add `$PI_SRC_DIR` to your `PYTHONPATH` and you're good to go. E.g.,

```shell
PYTHONPATH=$PI_SRC_DIR pytest ../tests/unit/*
```

**Why build the `install` target?** Because you can't do a `pip install . -e` (editable install) because of the pybind/C-extension so this is the next best thing.

Note, if you're using CLion and you're getting something like

```shell
Process finished with exit code 127
```

you need to disable `Add content roots to PYTHONPATH` and `Add source roots to PYTHONPATH` [in Run/Debug Configurations](https://stackoverflow.com/a/48471173).

If you're fancy you can add these CMake flags:

```shell
-DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld"
-DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld"
-DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=lld"
-DCMAKE_C_COMPILER_LAUNCHER=ccache
-DCMAKE_CXX_COMPILER_LAUNCHER=ccache
```