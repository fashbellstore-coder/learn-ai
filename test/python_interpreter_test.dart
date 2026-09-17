import 'package:flutter_test/flutter_test.dart';
import 'package:learn_ai/data/runtime/python_interpreter.dart';

void main() {
  const py = PythonInterpreter();

  test('evaluates bindings, prints, and collections', () {
    expect(py.run('x = 3\ny = x\nx = 4\nprint(y)').stdout.trim(), '3');
    expect(py.run('print(len({1,1,2}), [1,2][0])').stdout.trim(), '2 1');
    final comp = py.run('print([n*n for n in range(4) if n % 2 == 0])');
    expect(comp.stderr, '');
    expect(comp.stdout.trim(), '[0, 4]');
  });

  test('evaluates functions, generators, and json', () {
    expect(py.run('def add(a, b=1):\n    return a + b\nprint(add(2), add(2, 3))').stdout.trim(), '3 5');
    expect(py.run('def g():\n    yield 1\n    yield 2\nprint(list(g()))').stdout.trim(), '[1, 2]');
    expect(py.run('import json\nprint(json.loads(\'{"k":1}\')["k"])').stdout.trim(), '1');
  });

  test('evaluates numpy broadcast shape', () {
    final r = py.run(
      'import numpy as np\na = np.ones((3, 1))\nb = np.array([1, 2, 3])\nprint((a + b).shape)',
    );
    expect(r.ok, isTrue);
    expect(r.stdout.trim(), '(3, 3)');
  });

  test('evaluates scipy linalg and sparse', () {
    final r = py.run(
      'import numpy as np\n'
      'from scipy import linalg\n'
      'from scipy.sparse import csr_matrix\n'
      'A = np.array([[2.0, 0.0], [0.0, 3.0]])\n'
      'print(linalg.det(A))\n'
      'X = csr_matrix(np.array([[1.0, 0.0], [0.0, 2.0]]))\n'
      'print(X.nnz, X.format)',
    );
    expect(r.ok, isTrue, reason: r.stderr);
    expect(r.stdout.trim(), '6.0\n2 csr');
  });

  test('evaluates matplotlib subplots and savefig', () {
    final r = py.run(
      'import matplotlib.pyplot as plt\n'
      'fig, ax = plt.subplots()\n'
      'ax.plot([1, 2, 3], [1, 4, 9])\n'
      'print(fig.get_size_inches())\n'
      'print(plt.savefig("line.png"))',
    );
    expect(r.ok, isTrue, reason: r.stderr);
    expect(r.stdout.trim(), '(6.0, 4.0)\nline.png');
  });

  test('evaluates pandas frame, groupby, and filter', () {
    final r = py.run(
      'import pandas as pd\n'
      'df = pd.DataFrame({"user": [1, 1, 2], "spend": [10, None, 4]})\n'
      'print(df.shape)\n'
      'print(df["spend"].isna())\n'
      'print(df.fillna(0).groupby("user")["spend"].sum())',
    );
    expect(r.ok, isTrue, reason: r.stderr);
    expect(r.stdout.trim(), '(3, 2)\n[False, True, False]\n{1: 10, 2: 4}');
  });

  test('evaluates numpy matmul, nan, and 2d slice', () {
    final mul = py.run(
      'import numpy as np\nprint((np.ones((2, 3)) @ np.ones((3, 4))).shape)\n'
      'A = np.eye(2)\nprint((A @ A).sum())',
    );
    expect(mul.ok, isTrue, reason: mul.stderr);
    expect(mul.stdout.trim(), '(2, 4)\n2.0');

    final nan = py.run(
      'import numpy as np\nx = np.array([1.0, np.nan, 2.0])\nprint(np.isnan(x).tolist())',
    );
    expect(nan.ok, isTrue, reason: nan.stderr);
    expect(nan.stdout.trim(), '[0.0, 1.0, 0.0]');

    final sl = py.run(
      'import numpy as np\nX = np.ones((8, 4))\nprint(X[0:2].shape)',
    );
    expect(sl.ok, isTrue, reason: sl.stderr);
    expect(sl.stdout.trim(), '(2, 4)');
  });

  test('evaluates gradient descent loop and f-strings', () {
    final r = py.run(
      'def loss(w): return (w - 3) ** 2\n'
      'def grad(w): return 2 * (w - 3)\n'
      'w, lr = 10.0, 0.1\n'
      'for _ in range(25):\n'
      '    w = w - lr * grad(w)\n'
      'print(f"w={w:.4f}  L={loss(w):.6f}")',
    );
    expect(r.ok, isTrue, reason: r.stderr);
    expect(r.stdout.trim(), startsWith('w=3.02'));
  });

  test('evaluates slices, isinstance, bitwise, and input', () {
    expect(py.run('print("learn"[1:4])').stdout.trim(), 'ear');
    expect(py.run('print(isinstance(3, int), 5 & 3)').stdout.trim(), 'True 1');
    expect(py.run('print(input())').stdout.trim(), 'Ada');
    expect(py.run('print(any([0, 1]), all([1, 1]))').stdout.trim(), 'True True');
  });

  test('evaluates tensorflow constant shape', () {
    final r = py.run('import tensorflow as tf\nx = tf.constant([1.0, 2.0])\nprint(x.shape)');
    expect(r.ok, isTrue, reason: r.stderr);
    expect(r.stdout.trim(), '(2,)');
  });
}
