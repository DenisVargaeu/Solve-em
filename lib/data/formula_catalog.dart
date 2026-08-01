library;

import '../domain/entities/formula.dart';

/// Curated, offline formula catalog grouped by topic.
///
/// Rendered with LaTeX in the Formula Library screen.

class FormulaCatalog {
  FormulaCatalog._();

  static const List<Formula> all = [
    // ── Algebra ───────────────────────────────────────────────────────────
    Formula(
      id: 'quadratic',
      topic: 'Algebra',
      name: 'Quadratic formula',
      latex: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
      description:
          r'Solves $ax^2 + bx + c = 0$. The discriminant $b^2 - 4ac$ tells '
          r'you how many real roots exist.',
      example: r'For $x^2 - 5x + 6 = 0$: $x = 2$ or $x = 3$.',
    ),
    Formula(
      id: 'binomial',
      topic: 'Algebra',
      name: 'Binomial theorem',
      latex: r'(a + b)^n = \sum_{k=0}^{n} \binom{n}{k} a^{n-k} b^k',
      description: 'Expands powers of a binomial using binomial coefficients.',
    ),
    Formula(
      id: 'difference_squares',
      topic: 'Algebra',
      name: 'Difference of squares',
      latex: r'a^2 - b^2 = (a - b)(a + b)',
      description: 'Factors the difference of two perfect squares.',
    ),
    Formula(
      id: 'exponent_laws',
      topic: 'Algebra',
      name: 'Laws of exponents',
      latex: r'a^m \cdot a^n = a^{m+n}, \quad \frac{a^m}{a^n} = a^{m-n}',
      description:
          'Rules for multiplying and dividing powers of the same base.',
    ),
    Formula(
      id: 'log_change_base',
      topic: 'Algebra',
      name: 'Change of base (logarithms)',
      latex: r'\log_b x = \frac{\log_k x}{\log_k b}',
      description: 'Convert a logarithm to any other base.',
    ),

    // ── Geometry ──────────────────────────────────────────────────────────
    Formula(
      id: 'pythagoras',
      topic: 'Geometry',
      name: 'Pythagorean theorem',
      latex: r'a^2 + b^2 = c^2',
      description: 'Relates the legs of a right triangle to its hypotenuse.',
      example: r'For legs 3 and 4: $c = 5$.',
    ),
    Formula(
      id: 'circle_area',
      topic: 'Geometry',
      name: 'Area of a circle',
      latex: r'A = \pi r^2',
      description: r'Area of a circle with radius $r$.',
    ),
    Formula(
      id: 'sphere_volume',
      topic: 'Geometry',
      name: 'Volume of a sphere',
      latex: r'V = \frac{4}{3} \pi r^3',
      description: r'Volume enclosed by a sphere of radius $r$.',
    ),
    Formula(
      id: 'triangle_area',
      topic: 'Geometry',
      name: 'Area of a triangle',
      latex: r'A = \frac{1}{2} b h',
      description: 'Half the base times the height.',
    ),
    Formula(
      id: 'distance_points',
      topic: 'Geometry',
      name: 'Distance between points',
      latex: r'd = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2}',
      description: 'Euclidean distance in the plane.',
    ),

    // ── Trigonometry ──────────────────────────────────────────────────────
    Formula(
      id: 'sin_cos_tan',
      topic: 'Trigonometry',
      name: 'SOH-CAH-TOA',
      latex:
          r'\sin\theta = \frac{o}{h}, \quad \cos\theta = \frac{a}{h}, \quad \tan\theta = \frac{o}{a}',
      description: 'The three basic trigonometric ratios in a right triangle.',
    ),
    Formula(
      id: 'pythag_identity',
      topic: 'Trigonometry',
      name: 'Pythagorean identity',
      latex: r'\sin^2\theta + \cos^2\theta = 1',
      description: 'The fundamental identity linking sine and cosine.',
    ),
    Formula(
      id: 'double_angle',
      topic: 'Trigonometry',
      name: 'Double angle (sine)',
      latex: r'\sin 2\theta = 2\sin\theta \cos\theta',
      description: 'Sine of twice an angle.',
    ),
    Formula(
      id: 'law_of_sines',
      topic: 'Trigonometry',
      name: 'Law of sines',
      latex: r'\frac{\sin A}{a} = \frac{\sin B}{b} = \frac{\sin C}{c}',
      description:
          'Ratio of a side to the sine of its opposite angle is constant.',
    ),

    // ── Calculus ──────────────────────────────────────────────────────────
    Formula(
      id: 'power_rule',
      topic: 'Calculus',
      name: 'Power rule',
      latex: r'\frac{d}{dx} x^n = n x^{n-1}',
      description: 'Derivative of a power function.',
    ),
    Formula(
      id: 'product_rule',
      topic: 'Calculus',
      name: 'Product rule',
      latex: r"\frac{d}{dx}\big(f(x)g(x)\big) = f'(x)g(x) + f(x)g'(x)",
      description: 'Derivative of a product of two functions.',
    ),
    Formula(
      id: 'chain_rule',
      topic: 'Calculus',
      name: 'Chain rule',
      latex: r"\frac{d}{dx} f(g(x)) = f'(g(x)) \cdot g'(x)",
      description: 'Derivative of a composite function.',
    ),
    Formula(
      id: 'fundamental_theorem',
      topic: 'Calculus',
      name: 'Fundamental theorem of calculus',
      latex: r'\int_{a}^{b} f(x)\,dx = F(b) - F(a)',
      description: 'Links differentiation and definite integration.',
    ),

    // ── Statistics & Probability ──────────────────────────────────────────
    Formula(
      id: 'mean',
      topic: 'Statistics & Probability',
      name: 'Arithmetic mean',
      latex: r'\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i',
      description: 'Average of a data set.',
    ),
    Formula(
      id: 'stddev',
      topic: 'Statistics & Probability',
      name: 'Standard deviation',
      latex: r'\sigma = \sqrt{\frac{1}{n}\sum_{i=1}^{n}(x_i - \bar{x})^2}',
      description: 'Measures the spread of data around the mean.',
    ),
    Formula(
      id: 'zscore',
      topic: 'Statistics & Probability',
      name: 'Z-score',
      latex: r'z = \frac{x - \mu}{\sigma}',
      description: 'Number of standard deviations from the mean.',
    ),
    Formula(
      id: 'bayes',
      topic: 'Statistics & Probability',
      name: 'Bayes\u2019 theorem',
      latex: r'P(A|B) = \frac{P(B|A)\,P(A)}{P(B)}',
      description: 'Updates a probability given new evidence.',
    ),
    Formula(
      id: 'combinations',
      topic: 'Statistics & Probability',
      name: 'Combinations',
      latex: r'\binom{n}{k} = \frac{n!}{k!(n-k)!}',
      description:
          r'Number of ways to choose $k$ items from $n$ without order.',
    ),
  ];

  /// Groups formulas by topic, preserving catalog order.
  static List<MapEntry<String, List<Formula>>> get grouped {
    final map = <String, List<Formula>>{};
    for (final f in all) {
      map.putIfAbsent(f.topic, () => []).add(f);
    }
    return map.entries.toList();
  }
}
