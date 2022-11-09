extends Node
# See https://en.wikipedia.org/wiki/Musical_note#Note_frequency_(in_hertz)
# The notes are calculated per octave to improve floating point precision

const A0: float = 27.5
const A_SHARP0: float = pow(2.0, 1/12.0) * A0
const B_FLAT0: float = A_SHARP0
const B0: float = pow(2.0, 2/12.0) * A0
const C0: float = pow(2.0, 3/12.0) * A0
const C_SHARP0: float = pow(2.0, 4/12.0) * A0
const D_FLAT0: float = C_SHARP0
const D0: float = pow(2.0, 5/12.0) * A0
const D_SHARP0: float = pow(2.0, 6/12.0) * A0
const E_FLAT0: float = D_SHARP0
const E0: float = pow(2.0, 7/12.0) * A0
const F0: float = pow(2.0, 8/12.0) * A0
const F_SHARP0: float = pow(2.0, 9/12.0) * A0
const G_FLAT0: float = F_SHARP0
const G0: float = pow(2.0, 10/12.0) * A0
const G_SHARP0: float = pow(2.0, 11/12.0) * A0
const A_FLAT0: float = G_SHARP0

const A1: float = 55.0
const A_SHARP1: float = pow(2.0, 1/12.0) * A1
const B_FLAT1: float = A_SHARP1
const B1: float = pow(2.0, 2/12.0) * A1
const C1: float = pow(2.0, 3/12.0) * A1
const C_SHARP1: float = pow(2.0, 4/12.0) * A1
const D_FLAT1: float = C_SHARP1
const D1: float = pow(2.0, 5/12.0) * A1
const D_SHARP1: float = pow(2.0, 6/12.0) * A1
const E_FLAT1: float = D_SHARP1
const E1: float = pow(2.0, 7/12.0) * A1
const F1: float = pow(2.0, 8/12.0) * A1
const F_SHARP1: float = pow(2.0, 9/12.0) * A1
const G_FLAT1: float = F_SHARP1
const G1: float = pow(2.0, 10/12.0) * A1
const G_SHARP1: float = pow(2.0, 11/12.0) * A1
const A_FLAT1: float = G_SHARP1

const A2: float = 110.0
const A_SHARP2: float = pow(2.0, 1/12.0) * A2
const B_FLAT2: float = A_SHARP2
const B2: float = pow(2.0, 2/12.0) * A2
const C2: float = pow(2.0, 3/12.0) * A2
const C_SHARP2: float = pow(2.0, 4/12.0) * A2
const D_FLAT2: float = C_SHARP2
const D2: float = pow(2.0, 5/12.0) * A2
const D_SHARP2: float = pow(2.0, 6/12.0) * A2
const E_FLAT2: float = D_SHARP2
const E2: float = pow(2.0, 7/12.0) * A2
const F2: float = pow(2.0, 8/12.0) * A2
const F_SHARP2: float = pow(2.0, 9/12.0) * A2
const G_FLAT2: float = F_SHARP2
const G2: float = pow(2.0, 10/12.0) * A2
const G_SHARP2: float = pow(2.0, 11/12.0) * A2
const A_FLAT2: float = G_SHARP2

const A3: float = 220.0
const A_SHARP3: float = pow(2.0, 1/12.0) * A3
const B_FLAT3: float = A_SHARP3
const B3: float = pow(2.0, 2/12.0) * A3
const C3: float = pow(2.0, 3/12.0) * A3
const C_SHARP3: float = pow(2.0, 4/12.0) * A3
const D_FLAT3: float = C_SHARP3
const D3: float = pow(2.0, 5/12.0) * A3
const D_SHARP3: float = pow(2.0, 6/12.0) * A3
const E_FLAT3: float = D_SHARP3
const E3: float = pow(2.0, 7/12.0) * A3
const F3: float = pow(2.0, 8/12.0) * A3
const F_SHARP3: float = pow(2.0, 9/12.0) * A3
const G_FLAT3: float = F_SHARP3
const G3: float = pow(2.0, 10/12.0) * A3
const G_SHARP3: float = pow(2.0, 11/12.0) * A3
const A_FLAT3: float = G_SHARP3

const A4: float = 440.0
const A_SHARP4: float = pow(2.0, 1/12.0) * A4
const B_FLAT4: float = A_SHARP4
const B4: float = pow(2.0, 2/12.0) * A4
const C4: float = pow(2.0, 3/12.0) * A4
const C_SHARP4: float = pow(2.0, 4/12.0) * A4
const D_FLAT4: float = C_SHARP4
const D4: float = pow(2.0, 5/12.0) * A4
const D_SHARP4: float = pow(2.0, 6/12.0) * A4
const E_FLAT4: float = D_SHARP4
const E4: float = pow(2.0, 7/12.0) * A4
const F4: float = pow(2.0, 8/12.0) * A4
const F_SHARP4: float = pow(2.0, 9/12.0) * A4
const G_FLAT4: float = F_SHARP4
const G4: float = pow(2.0, 10/12.0) * A4
const G_SHARP4: float = pow(2.0, 11/12.0) * A4
const A_FLAT4: float = G_SHARP4

const A5: float = 880.0
const A_SHARP5: float = pow(2.0, 1/12.0) * A5
const B_FLAT5: float = A_SHARP4
const B5: float = pow(2.0, 2/12.0) * A5
const C5: float = pow(2.0, 3/12.0) * A5
const C_SHARP5: float = pow(2.0, 4/12.0) * A5
const D_FLAT5: float = C_SHARP5
const D5: float = pow(2.0, 5/12.0) * A5
const D_SHARP5: float = pow(2.0, 6/12.0) * A5
const E_FLAT5: float = D_SHARP5
const E5: float = pow(2.0, 7/12.0) * A5
const F5: float = pow(2.0, 8/12.0) * A5
const F_SHARP5: float = pow(2.0, 9/12.0) * A5
const G_FLAT5: float = F_SHARP5
const G5: float = pow(2.0, 10/12.0) * A5
const G_SHARP5: float = pow(2.0, 11/12.0) * A5
const A_FLAT5: float = G_SHARP5

const A6: float = 110.0
const A_SHARP6: float = pow(2.0, 1/12.0) * A6
const B_FLAT6: float = A_SHARP6
const B6: float = pow(2.0, 2/12.0) * A6
const C6: float = pow(2.0, 3/12.0) * A6
const C_SHARP6: float = pow(2.0, 4/12.0) * A6
const D_FLAT6: float = C_SHARP6
const D6: float = pow(2.0, 5/12.0) * A6
const D_SHARP6: float = pow(2.0, 6/12.0) * A6
const E_FLAT6: float = D_SHARP6
const E6: float = pow(2.0, 7/12.0) * A6
const F6: float = pow(2.0, 8/12.0) * A6
const F_SHARP6: float = pow(2.0, 9/12.0) * A6
const G_FLAT6: float = F_SHARP6
const G6: float = pow(2.0, 10/12.0) * A6
const G_SHARP6: float = pow(2.0, 11/12.0) * A6
const A_FLAT6: float = G_SHARP6

const A7: float = 110.0
const A_SHARP7: float = pow(2.0, 1/12.0) * A7
const B_FLAT7: float = A_SHARP7
const B7: float = pow(2.0, 2/12.0) * A7
const C7: float = pow(2.0, 3/12.0) * A7
const C_SHARP7: float = pow(2.0, 4/12.0) * A7
const D_FLAT7: float = C_SHARP7
const D7: float = pow(2.0, 5/12.0) * A7
const D_SHARP7: float = pow(2.0, 6/12.0) * A7
const E_FLAT7: float = D_SHARP7
const E7: float = pow(2.0, 7/12.0) * A7
const F7: float = pow(2.0, 8/12.0) * A7
const F_SHARP7: float = pow(2.0, 9/12.0) * A7
const G_FLAT7: float = F_SHARP7
const G7: float = pow(2.0, 10/12.0) * A7
const G_SHARP7: float = pow(2.0, 11/12.0) * A7
const A_FLAT7: float = G_SHARP7

const OCTAVES = [
	{
		A = A0,
		A_SHARP = A_SHARP0,
		B_FLAT = B_FLAT0,
		B = B0,
		C = C0,
		C_SHARP = C_SHARP0,
		D_FLAT = D_FLAT0,
		D = D0,
		D_SHARP = D_SHARP0,
		E_FLAT = E_FLAT0,
		E = E0,
		F = F0,
		F_SHARP = F_SHARP0,
		G_FLAT = G_FLAT0,
		G = G0,
		G_SHARP = G_SHARP0,
		A_FLAT = A_FLAT0
	},
	{
		A = A1,
		A_SHARP = A_SHARP1,
		B_FLAT = B_FLAT1,
		B = B1,
		C = C1,
		C_SHARP = C_SHARP1,
		D_FLAT = D_FLAT1,
		D = D1,
		D_SHARP = D_SHARP1,
		E_FLAT = E_FLAT1,
		E = E1,
		F = F1,
		F_SHARP = F_SHARP1,
		G_FLAT = G_FLAT1,
		G = G1,
		G_SHARP = G_SHARP1,
		A_FLAT = A_FLAT1
	},
	{
		A = A2,
		A_SHARP = A_SHARP2,
		B_FLAT = B_FLAT2,
		B = B2,
		C = C2,
		C_SHARP = C_SHARP2,
		D_FLAT = D_FLAT2,
		D = D2,
		D_SHARP = D_SHARP2,
		E_FLAT = E_FLAT2,
		E = E2,
		F = F2,
		F_SHARP = F_SHARP2,
		G_FLAT = G_FLAT2,
		G = G2,
		G_SHARP = G_SHARP2,
		A_FLAT = A_FLAT2
	},
	{
		A = A3,
		A_SHARP = A_SHARP3,
		B_FLAT = B_FLAT3,
		B = B3,
		C = C3,
		C_SHARP = C_SHARP3,
		D_FLAT = D_FLAT3,
		D = D3,
		D_SHARP = D_SHARP3,
		E_FLAT = E_FLAT3,
		E = E3,
		F = F3,
		F_SHARP = F_SHARP3,
		G_FLAT = G_FLAT3,
		G = G3,
		G_SHARP = G_SHARP3,
		A_FLAT = A_FLAT3
	},
	{
		A = A4,
		A_SHARP = A_SHARP4,
		B_FLAT = B_FLAT4,
		B = B4,
		C = C4,
		C_SHARP = C_SHARP4,
		D_FLAT = D_FLAT4,
		D = D4,
		D_SHARP = D_SHARP4,
		E_FLAT = E_FLAT4,
		E = E4,
		F = F4,
		F_SHARP = F_SHARP4,
		G_FLAT = G_FLAT4,
		G = G4,
		G_SHARP = G_SHARP4,
		A_FLAT = A_FLAT4
	},
	{
		A = A5,
		A_SHARP = A_SHARP5,
		B_FLAT = B_FLAT5,
		B = B5,
		C = C5,
		C_SHARP = C_SHARP5,
		D_FLAT = D_FLAT5,
		D = D5,
		D_SHARP = D_SHARP5,
		E_FLAT = E_FLAT5,
		E = E5,
		F = F5,
		F_SHARP = F_SHARP5,
		G_FLAT = G_FLAT5,
		G = G5,
		G_SHARP = G_SHARP5,
		A_FLAT = A_FLAT5
	},
	{
		A = A6,
		A_SHARP = A_SHARP6,
		B_FLAT = B_FLAT6,
		B = B6,
		C = C6,
		C_SHARP = C_SHARP6,
		D_FLAT = D_FLAT6,
		D = D6,
		D_SHARP = D_SHARP6,
		E_FLAT = E_FLAT6,
		E = E6,
		F = F6,
		F_SHARP = F_SHARP6,
		G_FLAT = G_FLAT6,
		G = G6,
		G_SHARP = G_SHARP6,
		A_FLAT = A_FLAT6
	},
	{
		A = A7,
		A_SHARP = A_SHARP7,
		B_FLAT = B_FLAT7,
		B = B7,
		C = C7,
		C_SHARP = C_SHARP7,
		D_FLAT = D_FLAT7,
		D = D7,
		D_SHARP = D_SHARP7,
		E_FLAT = E_FLAT7,
		E = E7,
		F = F7,
		F_SHARP = F_SHARP7,
		G_FLAT = G_FLAT7,
		G = G7,
		G_SHARP = G_SHARP7,
		A_FLAT = A_FLAT7
	},
]

const CHROMATIC = [
	A0,
	A_SHARP0,
	B0,
	C0,
	C_SHARP0,
	D0,
	D_SHARP0,
	E0,
	F0,
	F_SHARP0,
	G0,
	G_SHARP0,
	A1,
	A_SHARP1,
	B1,
	C1,
	C_SHARP1,
	D1,
	D_SHARP1,
	E1,
	F1,
	F_SHARP1,
	G1,
	G_SHARP1,
	A2,
	A_SHARP2,
	B2,
	C2,
	C_SHARP2,
	D2,
	D_SHARP2,
	E2,
	F2,
	F_SHARP2,
	G2,
	G_SHARP2,
	A3,
	A_SHARP3,
	B3,
	C3,
	C_SHARP3,
	D3,
	D_SHARP3,
	E3,
	F3,
	F_SHARP3,
	G3,
	G_SHARP3,
	A4,
	A_SHARP4,
	B4,
	C4,
	C_SHARP4,
	D4,
	D_SHARP4,
	E4,
	F4,
	F_SHARP4,
	G4,
	G_SHARP4,
	A5,
	A_SHARP5,
	B5,
	C5,
	C_SHARP5,
	D5,
	D_SHARP5,
	E5,
	F5,
	F_SHARP5,
	G5,
	G_SHARP5,
	A6,
	A_SHARP6,
	B6,
	C6,
	C_SHARP6,
	D6,
	D_SHARP6,
	E6,
	F6,
	F_SHARP6,
	G6,
	G_SHARP6,
	A7,
	A_SHARP7,
	B7,
	C7,
	C_SHARP7,
	D7,
	D_SHARP7,
	E7,
	F7,
	F_SHARP7,
	G7,
	G_SHARP7
]
