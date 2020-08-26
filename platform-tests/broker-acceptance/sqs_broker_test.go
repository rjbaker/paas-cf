package broker_acceptance_test

import (
	"io/ioutil"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/workflowhelpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("SQS broker", func() {
	const (
		brokerName       = "sqs-broker"
		serviceName      = "aws-sqs-queue"
		standardPlanName = "standard"
		fifoPlanName     = "fifo"
	)

	// Enable service access for the ephemeral test org.
	// FIXME: remove this BeforeEach block once sqs is enabled for all
	BeforeEach(func() {
		workflowhelpers.AsUser(testContext.AdminUserContext(), testContext.ShortTimeout(), func() {
			standard := cf.Cf("enable-service-access",
				"-o", testContext.TestSpace.OrganizationName(),
				"-b", brokerName,
				"-p", standardPlanName,
			).Wait(testConfig.DefaultTimeoutDuration())
			Expect(standard).To(Exit(0))
			fifo := cf.Cf("enable-service-access",
				"-o", testContext.TestSpace.OrganizationName(),
				"-b", brokerName,
				"-p", standardPlanName,
			).Wait(testConfig.DefaultTimeoutDuration())
			Expect(fifo).To(Exit(0))
		})
	})

	It("is registered in the marketplace", func() {
		plans := cf.Cf("marketplace").Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans).To(Say(serviceName))
	})

	It("has the expected plans available", func() {
		plans := cf.Cf("marketplace", "-s", serviceName).Wait(testConfig.DefaultTimeoutDuration())
		Expect(plans).To(Exit(0))
		Expect(plans.Out.Contents()).To(ContainSubstring(standardPlanName))
		Expect(plans.Out.Contents()).To(ContainSubstring(fifoPlanName))
	})

	Context("creating an SQS queue", func() {
		var (
			appName             string
			serviceInstanceName string
		)

		It("is accessible from the healthcheck app", func() {

			appName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-sqs-queue")

			By("creating a standard queue service: "+serviceInstanceName, func() {
				Expect(cf.Cf("create-service", serviceName, standardPlanName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceCreationCompletion(serviceInstanceName)
			})

			defer By("deleting a standard queue service", func() {
				Expect(cf.Cf("delete-service", serviceInstanceName, "-f").Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})

			By("pushing the healthcheck app", func() {
				Expect(cf.Cf(
					"push", appName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			defer By("deleting the app", func() {
				cf.Cf("delete", appName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("binding the service", func() {
				Expect(cf.Cf("bind-service", appName, serviceInstanceName).Wait(testConfig.DefaultTimeoutDuration())).To(Exit(0))
			})

			By("starting the app", func() {
				Expect(cf.Cf("start", appName).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("testing the SQS queue access from the app", func() {
				resp, err := httpClient.Get(helpers.AppUri(appName, "/sqs-test", testConfig))
				Expect(err).NotTo(HaveOccurred())
				body, err := ioutil.ReadAll(resp.Body)
				Expect(err).NotTo(HaveOccurred())
				resp.Body.Close()
				Expect(resp.StatusCode).To(Equal(200), "Got %d response from healthcheck app. Response body:\n%s\n", resp.StatusCode, string(body))
			})

		})
	})

	Context("multiple operations against a single queue", func() {
		var (
			appOneName          string
			appTwoName          string
			serviceInstanceName string
		)

		BeforeEach(func() {
			appOneName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")
			appTwoName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "APP")

			By("deploying a first app", func() {
				Expect(cf.Cf(
					"push", appOneName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			By("deploying a second app", func() {
				Expect(cf.Cf(
					"push", appTwoName,
					"--no-start",
					"-b", testConfig.GetGoBuildpackName(),
					"-p", "../example-apps/healthcheck",
					"-f", "../example-apps/healthcheck/manifest.yml",
					"-d", testConfig.GetAppsDomain(),
				).Wait(testConfig.CfPushTimeoutDuration())).To(Exit(0))
			})

			serviceInstanceName = generator.PrefixedRandomName(testConfig.GetNamePrefix(), "test-sqs-queue")

			By("creating the service: "+serviceInstanceName, func() {
				Expect(
					cf.
						Cf("create-service", serviceName, standardPlanName, serviceInstanceName).
						Wait(testConfig.DefaultTimeoutDuration()),
				).
					To(Exit(0))
				pollForServiceCreationCompletion(serviceInstanceName)
			})

			By("Waiting for AWS to be eventually consistent", func() {
				time.Sleep(10 * time.Second)
			})
		})

		AfterEach(func() {
			By("deleting the first app", func() {
				cf.Cf("delete", appOneName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("deleting the second app", func() {
				cf.Cf("delete", appTwoName, "-f").Wait(testConfig.DefaultTimeoutDuration())
			})

			By("deleting the service", func() {
				Expect(
					cf.Cf("delete-service", serviceInstanceName, "-f").
						Wait(testConfig.DefaultTimeoutDuration()),
				).To(Exit(0))
				pollForServiceDeletionCompletion(serviceInstanceName)
			})
		})

		It("do not run in to race conditions", func(done Done) {
			By("binding the two apps simultaneously, we should see no errors", func() {
				bindAppOneChan := make(chan int)
				bindAppTwoChan := make(chan int)

				bindServiceToAppAsync(appOneName, serviceInstanceName, bindAppOneChan)
				bindServiceToAppAsync(appTwoName, serviceInstanceName, bindAppTwoChan)

				Expect(<-bindAppOneChan).To(Equal(0))
				Expect(<-bindAppTwoChan).To(Equal(0))
			})

			By("Waiting for AWS to be eventually consistent", func() {
				time.Sleep(10 * time.Second)
			})

			By("unbinding the two apps simultaneously, we should see no errors", func() {
				unbindAppOneChan := make(chan int)
				unbindAppTwoChan := make(chan int)

				unbindServiceFromAppAsync(appOneName, serviceInstanceName, unbindAppOneChan)
				unbindServiceFromAppAsync(appTwoName, serviceInstanceName, unbindAppTwoChan)

				Expect(<-unbindAppOneChan).To(Equal(0))
				Expect(<-unbindAppTwoChan).To(Equal(0))
			})

			close(done)
		}, 60, // Override default timeout of 1 second for async to be one minute
		)
	})
})
