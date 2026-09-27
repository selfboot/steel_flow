# Steel Weight Calculation: Formulas, kg per Metre and a Worked Example

*Calculate flat bar and plate weight, check material costs, and leave a PDF quote someone else can verify.*

A steel weight calculation starts with three things: the shape, its dimensions and the material density. The arithmetic is usually short. The mistakes tend to come from mixing millimetres and metres, forgetting the number of pieces, or comparing prices quoted in different units.

This guide works through a 100 × 10 mm flat bar order, then shows how to carry the result into a material quote. You can follow it with a calculator or spreadsheet.

> Disclosure: I develop SteelFlow, the iPhone app shown below. This article was prepared with AI assistance. The formulas work without the app. The prices, customers and projects shown are fictional examples, not live market data.

## The steel weight calculation formula

For a uniform solid piece:

**Weight in kg = cross-sectional area in m² × length in m × density in kg/m³**

Technically, this calculates mass; “weight” is the term commonly used in material ordering. For the carbon-steel examples here, use **7,850 kg/m³**. The Steel Construction Institute also uses this density when calculating section mass per metre. [SCI section tables](https://steelconstruction.info.iceblue-digital.co.uk/images/b/b7/SCI_P363.pdf)

Use the density appropriate to the material you are actually buying. Changing the material while leaving the density unchanged can make a tidy calculation wrong.

## Flat bar weight per metre

For a rectangular flat bar, the cross-sectional area is width × thickness. If both dimensions are in millimetres, the carbon-steel shortcut is:

**kg per metre = width (mm) × thickness (mm) × 0.00785**

The constant includes the conversion from mm² to m² and the assumed density. It is not a universal constant for every metal.

Take an order of **18 pieces**, each **100 mm wide × 10 mm thick × 6 m long**:

- Per metre: 100 × 10 × 0.00785 = **7.85 kg/m**
- Per six-metre piece: 7.85 × 6 = **47.10 kg**
- For 18 pieces: 47.10 × 18 = **847.80 kg**

The same order contains **108 metres** of bar. Keep both totals: one supplier may quote by weight and another by length.

![SteelFlow flat bar calculation showing 100 mm width, 10 mm thickness and 847.8 kg total weight.](../2026-09-10-compare-steel-prices/screenshots/calculation.png)

*Real English app screen captured in an iPhone simulator. The full input is 18 pieces at 6 m each; some fields are below the visible area.*

## Steel plate weight: the same method, different dimensions

For a rectangular plate, calculate its volume from width, length and thickness. A convenient mixed-unit formula is:

**Plate weight in kg = width (m) × length (m) × thickness (mm) × 7.85**

For one **1 m × 2 m × 10 mm** plate:

**1 × 2 × 10 × 7.85 = 157 kg**

Notice the units written next to the dimensions. Here the width and length are in metres, while thickness is in millimetres. If all three dimensions are in millimetres, the multiplier would instead be **0.00000785**.

For a quick check, a 10 mm carbon-steel plate weighs **78.5 kg per square metre** under the same density assumption. A two-square-metre plate should therefore weigh twice as much.

## Why one formula does not cover every profile

The underlying rule—volume × density—stays the same. The cross-sectional area changes.

- **Solid round bar:** use the area of a circle, π × diameter² ÷ 4.
- **Round tube:** subtract the inner circle from the outer circle. The inner diameter is the outer diameter minus twice the wall thickness.
- **Rolled angles, channels and beams:** use the appropriate published section mass where available. Nominal rectangles do not capture every fillet and corner.

Keep all area dimensions in the same units before multiplying. In particular, a tube’s wall thickness is not its inner diameter, and a radius is half a diameter.

## Turn kilograms into a material cost

Suppose the flat bar supplier quotes **$0.74/kg**. The material subtotal is:

**847.80 × $0.74 = $627.37**, rounded to cents.

For the same specification and quantity, compare that with:

- **$5.90 per metre:** 108 × $5.90 = **$637.20**
- **$35 per six-metre piece:** 18 × $35 = **$630.00**

The price per kg gives the lowest material subtotal in this example, but it is only **$2.63** below the per-piece offer. Delivery or cutting charges could reverse the result. Match grade, dimensions, finish, quantity and delivered scope before deciding which offer is cheaper.

To convert a rate yourself:

**Price per metre = price per kg × kg per metre**

Keep intermediate values unrounded and round the final line total. Also identify the currency and distinguish a metric tonne from a US short ton.

For a longer example including delivery charges and waste allowances, see my [guide to comparing steel prices per kg, per metre and per piece](https://medium.com/@xuezaigds/how-to-compare-steel-prices-per-kg-per-metre-and-per-piece-de2982e3d2de).

## What to keep in a PDF material quote

A weight total is easier to trust when the reader can reconstruct it. Before sharing a PDF, check that it includes:

- Material grade, profile and dimensions
- Length per piece and number of pieces
- The weight basis: theoretical calculation, section table or measured weight
- Currency, unit price and pricing unit
- Cutting, delivery, waste and other charges, with their basis
- Quote date, validity, taxes and relevant terms

A percentage waste allowance is a costing assumption, not a cutting plan. If you are already buying and pricing whole stock lengths, check that an extra allowance does not count the same offcuts twice.

## Using a steel weight calculator on an iPhone

In SteelFlow, I keep this workflow together: choose the profile, enter the material and dimensions, check the calculated weight, save the item to a project, and review the project’s PDF quote before sharing it.

![Six real SteelFlow screens: profile selection, calculation, materials, projects, project totals and PDF quote preview.](../2026-09-10-compare-steel-prices/assets/feature-overview.png)

*The main pages at a glance. These are real English app screens from an iPhone simulator. The Harbor Canopy project is a separate fictional three-line example; its totals are not the flat bar order calculated above.*

![SteelFlow PDF quote preview for the fictional Harbor Canopy project.](../2026-09-10-compare-steel-prices/screenshots/quote.png)

*Check the line items and terms before exporting. Customer details and prices are demonstration data.*

The app uses prices you enter. It does not supply live steel prices, read quantities from construction drawings or perform structural design. The calculated weight is theoretical; actual dimensions, tolerances and the supplier’s billing basis still matter.

At the time of writing, the free tier supports two active projects, up to ten items per project and branded PDF exports. The one-time Pro purchase adds unlimited projects and items, company details, CSV export and removal of PDF branding. Check the current in-app offer for local pricing.

Before sending your next material enquiry, write the dimensions with their units, calculate one piece, multiply by quantity, and keep the pricing basis beside the total. That leaves a result you and the supplier can both check.

If you want to use the workflow shown here, [download **SteelFlow: Metal Calculator** on the App Store (US listing)](https://apps.apple.com/us/app/steelflow-metal-calculator/id6806282417).

If the link does not open the app page, search the App Store for **SteelFlow: Metal Calculator**. In the China mainland store, search for **SteelFlow 钢材重量计算器** ([China mainland listing](https://apps.apple.com/cn/app/steelflow-钢材重量计算器/id6806282417)).
