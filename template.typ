#let template(
  title: "Assignment Title",
  assignment: "Assignment Name",
  abstractTitle: "Abstract title",
  body) = [
  #set page(
    margin: (x: 1.5cm, y: 2cm),

    header: [
      #set text(size: 8pt, fill: luma(120))
      #title
      #h(1fr)
      #assignment
    ],

    footer: [
      #set text(size: 8pt, fill: luma(120))
      #align(right)[#context {
        let current = counter(page).get().first()
        let total = counter(page).final().first()
        [Page #current of #total]
      }]
    ]
  )

  #set heading(numbering: "1.")
  #show heading.where(level: 1): set text(size: 11pt)
  #show heading.where(level: 2): set text(size: 10pt)
  #show heading.where(level: 3): set text(size: 9pt)
  #show heading.where(level: 4): set text(size: 9pt)

  #set par(
    justify: true,
    leading: 0.55em,
    spacing: 1.0em,
  )

  #set text(
    font: "Libertinus Serif",
    size: 9pt,
    kerning: true,
    ligatures: true,
  )

  #show figure: set align(left)
  #show figure.caption: set text(size: 0.8em, style: "italic")
  #show figure.caption: set align(center)

  #set table(stroke: 0.5pt + rgb("333333"))

  #show raw.where(block: true): set block(fill: luma(230),
    outset: (left: -1em, right: -1em),
    inset: (left: 2em, right: 2em, top: 1em, bottom: 1em),
    radius: 0.5em, width: 100%)

  #set list(indent: 1em)
  #set enum(indent: 1em)

  #align(center)[
    *#abstractTitle*

    #v(0.5em)

    *Timothy Clarke* \
    University of Dundee \
    United Kingdom \
    2712139\@dundee.ac.uk
    #v(0.5em)
  ]

  #align(center)[
    #line(stroke: (0.7pt + gray), length: 75%)
    #v(1em)
  ]

  #set text(size: 10pt)
  #show link: set text(fill: rgb("#C60000"))
  #set rect(stroke: 0.5pt + rgb("333333"))

  #body
]

