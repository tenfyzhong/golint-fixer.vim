// this is a demo. 
// I use ale to check warnings. 
// the line has `--` we need to fix. 
package foo

import . "time" // MATCH /dot import/

import (
	"fmt"

	/* MATCH /blank import/ */ _ "os"

	/* MATCH /blank import/ */ _ "net/http"
	_ "path"
	"context"
	"net/url"
	"errors"
	"log"
	"flag"
)

type T int // MATCH /exported type T.*should.*comment.*or.*unexport/

type t_wow struct { // MATCH /underscore.*type.*t_wow/
	x_damn int      // MATCH /underscore.*field.*x_damn/
	Url    *url.URL // MATCH /struct field.*Url.*URL/
}

// Common styles in other languages that don't belong in Go.
const (
	CPP_CONST   = 1 // MATCH /ALL_CAPS.*CamelCase/
	kLeadingKay = 2 // MATCH /k.*leadingKay/

	HTML  = 3 // okay; no underscore
	X509B = 4 // ditto
)

var unexp = errors.New("some unexported error") // MATCH /error var.*unexp.*errFoo/

// Exp ...
var Exp = errors.New("some exported error") // MATCH /error var.*Exp.*ErrFoo/

func (T) F() {} // MATCH /exported method T\.F.*should.*comment.*or.*unexport/

// An invalid context.Context location
func y(s string, ctx context.Context) { // MATCH /context.Context should be the first parameter.*/
}

func f(x int) bool {
	if x > 0 {
		return true
	} else { // MATCH /if.*return.*else.*outdent/
		log.Printf("non-positive x: %d", x)
	}
	return false
}

// Check for error in the wrong location on 2 types
func k() (error, int) { // MATCH /error should be the last type/
	return nil, 0
}

func f2(x int) error {
	if x > 10 {
		return errors.New(fmt.Sprintf("something %d", x)) // MATCH /should replace.*errors\.New\(fmt\.Sprintf\(\.\.\.\)\).*fmt\.Errorf\(\.\.\.\)/ -> `		return fmt.Errorf("something %d", x)`
	}
	return nil
}

func addOne(x int) int {
	x += 1 // MATCH /x\+\+/
	return x
}

func f3() {
	var m map[string]int

	// with :=
	for x, _ := range m { // MATCH /should omit 2nd value.*range.*equivalent.*for x := range/ -> `	for x := range m {`
		_ = x
	}
	// with =
	var y string
	_ = y
	for y, _ = range m { // MATCH /should omit 2nd value.*range.*equivalent.*for y = range/
	}
}

type foo struct{}
type bar struct{}

func (this foo) f4() { // MATCH /should be a reflection of its identity/
}

func (self foo) f5() { // MATCH /should be a reflection of its identity/
}

func (b bar) f6() {
}

func (a bar) f7() { // MATCH /receiver name a should be consistent with previous receiver name b for bar/
}

// DonutMaker makes donuts.
type DonutMaker struct{} // MATCH /donut\.DonutMaker.*stutter/

var rpcTimeoutMsec = flag.Duration("rpc_timeout", 100*time.Millisecond, "some flag") // MATCH /Msec.*\*time.Duration/

var myInt int = 7                           // MATCH /should.*int.*myInt.*inferred/

var myZeroInt int = 0         // MATCH /should.*= 0.*myZeroInt.*zero value/
