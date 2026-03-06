Team project: numerical ramjet engine
Overview
The purpose of the team project is to give students an opportunity to demonstrate that they are able to independently apply the theory introduced in lectures in practical engineering analysis. Students are expected to work together
in teams of no more than four and no fewer than three.
Project brief
Develop a numerical algorithm which can design a ramjet engine. The inputs
for your code should be
(a) Free-stream pressure and temperature;
(b) Flight Mach number
(c) Normal shock strength
(d) Burner entry Mach number
(e) Burner temperature
(f) Burner pressure ratio (Pb/P2)
(g) Exhaust pressure ratio (P4/P1)
(h) Required thrust
The outputs of your code should be
(a) Inlet area
(b) Inlet throat area
(c) Burner entry area
(d) Burner exit area
(e) Nozzle throat area
(f) Exhaust area
(g) Thermodynamic efficiency
(h) Propulsive efficiency
1
Using the code you have developed, produce plots showing the variation of
thermodynamic and propulsive efficiency with each of the input parameters
above. When producing your plots, you will be required to hold some input
parameters constant: for this, you are free to use any reasonable values.
You may make any reasonable, justifiable assumptions you wish, though
these should be explicitly detailed and justified in the report.
Format
Each team should submit a single report consisting of the following sections:
(a) Report cover page: Should indicate the title, the names of the team members, the submission date and the course code. Only those team members
whose names appear on the cover sheet will receive credit for the coursework.
(b) Definitions: It may be a good idea to include a brief statement at the
beginning of your report defining the variables and terms you will be using.
The purpose of this is only to ensure that the assessor is able to understand
your solution. Similarly, it may clarify your solution if you include a labelled
diagram.
(c) Source code: Your report should include a printout of the complete source
code (including all subroutines or functions) used to produce your results.
You may write your code using any programming language you wish, providing that it is sufficiently intuitive that a non-specialist will be able to
interpret it (MATLAB, Python, C++, Basic, FORTRAN and MS Excel
are all acceptable). You may use any rudimentary in-built functions, but
you may not use any available prefabricated normal shock or isentropic flow
functions.
(d) Comment lines: Your code should include comment lines, explaining what
the code is doing at each step. Your comment lines should also indicate any
assumptions you have made. If I cannot figure out what your code is doing,
I cannot give you credit for it.
(e) Results and discussion: Generate the plots listed in the project requirements. Use proper scientific conventions for plotting (note that the MS
Excel default settings are not appropriate for the presentation of scientific
data). If, for given conditions, no solution exists, many solutions exist or
results are nonphysical, comment on why this occurs.
(f) Conclusion: Critically examine your results. Produce a brief statement
indicating whether or not you believe your code is working, and why. this
is a critical part of the project, as it demonstrates that not only could you
produce the code, but you could interpret and explain the results.
2
Electronic file submissions must be in PDF format only, and less than 5 MB
in size. For figures or plots, use line drawings only. Hand-drawn figures are
acceptable, so long as they are clear and of technical-drawing standard.
Remember, this is an exercise in analysis, not in report-writing. You do not
need to repeat material covered in class, and there is no need for a detailed
description. You only need to include an explanatory text in your report if you
cannot clearly explain what you are doing in comment lines. Reports should be
concise.
Submission
Reports should be submitted at or before 09:00 on the day of the penultimate
lecture (the due date is also published on BlackBoard). Reports should be
submitted electronically via the BlackBoard system.
Assessment
For details on the assessment of this project, please refer to the guidance from
the Department of Aeronautics General Office.
All of the students whose names appear on the cover sheet of a given report
will receive the same grade for the project. Students are responsible to manage
their own teams; any student whose name does not appear on any report will
receive a grade of 0%.
Notes
You will be awarded credit more for your approach to the problem than for
the correctness of your solution. The code has to work- it does not need to be
elegant, efficient or compact: it just has to be legible and understandable. ‘Brute
force’ search algorithms are perfectly acceptable. The idea here is primarily to
demonstrate that the code works, and to test the limitations of the assumptions.
Note that you may not be able to reproduce plots exactly as they appear in
the lecture slides: it is quite possible that you will arrive at different relationships. This does not necessarily mean that your solution is incorrect: it could
be because you have made different- though equally valid- assumptions.
The lecturer will be available for consultation via e-mail throughout.
3
