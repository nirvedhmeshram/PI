#include "mlir-c/Bindings/Python/Interop.h"

#include <pybind11/cast.h>
#include <pybind11/pybind11.h>
#include <pybind11/pytypes.h>
#include <vector>

#include "TorchOps.h"
#include "TorchTensor.h"
#include "TorchTypes.h"
#include "TorchValues.h"

namespace py = pybind11;
using namespace mlir::python;
using namespace mlir::torch;

PYBIND11_MODULE(_pi_mlir, m) {
  populateTorchMLIRTypes(m);
  populateTorchMLIRValues(m);
  populateTorchTensorOps(m);
  auto ops = m.def_submodule("ops");
  populateTorchMLIROps(ops);
}
