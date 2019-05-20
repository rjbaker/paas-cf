// Code generated by counterfeiter. DO NOT EDIT.
package fakes

import (
	"crypto/tls"
	"sync"

	"github.com/alphagov/paas-cf/tools/metrics/tlscheck"
)

type FakeCertChecker struct {
	DaysUntilExpiryStub        func(string, *tls.Config) (float64, error)
	daysUntilExpiryMutex       sync.RWMutex
	daysUntilExpiryArgsForCall []struct {
		arg1 string
		arg2 *tls.Config
	}
	daysUntilExpiryReturns struct {
		result1 float64
		result2 error
	}
	daysUntilExpiryReturnsOnCall map[int]struct {
		result1 float64
		result2 error
	}
	invocations      map[string][][]interface{}
	invocationsMutex sync.RWMutex
}

func (fake *FakeCertChecker) DaysUntilExpiry(arg1 string, arg2 *tls.Config) (float64, error) {
	fake.daysUntilExpiryMutex.Lock()
	ret, specificReturn := fake.daysUntilExpiryReturnsOnCall[len(fake.daysUntilExpiryArgsForCall)]
	fake.daysUntilExpiryArgsForCall = append(fake.daysUntilExpiryArgsForCall, struct {
		arg1 string
		arg2 *tls.Config
	}{arg1, arg2})
	fake.recordInvocation("DaysUntilExpiry", []interface{}{arg1, arg2})
	fake.daysUntilExpiryMutex.Unlock()
	if fake.DaysUntilExpiryStub != nil {
		return fake.DaysUntilExpiryStub(arg1, arg2)
	}
	if specificReturn {
		return ret.result1, ret.result2
	}
	fakeReturns := fake.daysUntilExpiryReturns
	return fakeReturns.result1, fakeReturns.result2
}

func (fake *FakeCertChecker) DaysUntilExpiryCallCount() int {
	fake.daysUntilExpiryMutex.RLock()
	defer fake.daysUntilExpiryMutex.RUnlock()
	return len(fake.daysUntilExpiryArgsForCall)
}

func (fake *FakeCertChecker) DaysUntilExpiryCalls(stub func(string, *tls.Config) (float64, error)) {
	fake.daysUntilExpiryMutex.Lock()
	defer fake.daysUntilExpiryMutex.Unlock()
	fake.DaysUntilExpiryStub = stub
}

func (fake *FakeCertChecker) DaysUntilExpiryArgsForCall(i int) (string, *tls.Config) {
	fake.daysUntilExpiryMutex.RLock()
	defer fake.daysUntilExpiryMutex.RUnlock()
	argsForCall := fake.daysUntilExpiryArgsForCall[i]
	return argsForCall.arg1, argsForCall.arg2
}

func (fake *FakeCertChecker) DaysUntilExpiryReturns(result1 float64, result2 error) {
	fake.daysUntilExpiryMutex.Lock()
	defer fake.daysUntilExpiryMutex.Unlock()
	fake.DaysUntilExpiryStub = nil
	fake.daysUntilExpiryReturns = struct {
		result1 float64
		result2 error
	}{result1, result2}
}

func (fake *FakeCertChecker) DaysUntilExpiryReturnsOnCall(i int, result1 float64, result2 error) {
	fake.daysUntilExpiryMutex.Lock()
	defer fake.daysUntilExpiryMutex.Unlock()
	fake.DaysUntilExpiryStub = nil
	if fake.daysUntilExpiryReturnsOnCall == nil {
		fake.daysUntilExpiryReturnsOnCall = make(map[int]struct {
			result1 float64
			result2 error
		})
	}
	fake.daysUntilExpiryReturnsOnCall[i] = struct {
		result1 float64
		result2 error
	}{result1, result2}
}

func (fake *FakeCertChecker) Invocations() map[string][][]interface{} {
	fake.invocationsMutex.RLock()
	defer fake.invocationsMutex.RUnlock()
	fake.daysUntilExpiryMutex.RLock()
	defer fake.daysUntilExpiryMutex.RUnlock()
	copiedInvocations := map[string][][]interface{}{}
	for key, value := range fake.invocations {
		copiedInvocations[key] = value
	}
	return copiedInvocations
}

func (fake *FakeCertChecker) recordInvocation(key string, args []interface{}) {
	fake.invocationsMutex.Lock()
	defer fake.invocationsMutex.Unlock()
	if fake.invocations == nil {
		fake.invocations = map[string][][]interface{}{}
	}
	if fake.invocations[key] == nil {
		fake.invocations[key] = [][]interface{}{}
	}
	fake.invocations[key] = append(fake.invocations[key], args)
}

var _ tlscheck.CertChecker = new(FakeCertChecker)
