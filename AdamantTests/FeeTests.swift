//
//  FeeTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 16.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class FeeTests: XCTestCase {
    func testTransferFee() {
		let estimatedFee = Decimal(0.5)
		XCTAssertEqual(estimatedFee, AdamantTransfersProvider().transferFee)
    }
	
	func testShortMessageFee() {
		let message = "A quick brown fox bought bitcoins in 2009. Good for you, mr fox. You quick brown mother fucker."
		let estimatedFee = Decimal(0.001)
		
		XCTAssertEqual(estimatedFee, AdamantMessage.text(message).fee)
	}
	
	func testLongMessageFee() {
		let message = """
The sperm whale's cerebrum is the largest in all mammalia, both in absolute and relative terms.
The olfactory system is reduced, suggesting that the sperm whale has a poor sense of taste and smell.
By contrast, the auditory system is enlarged.
The pyramidal tract is poorly developed, reflecting the reduction of its limbs.
"""
		let estimatedFee = Decimal(0.002)
		
		XCTAssertEqual(estimatedFee, AdamantMessage.text(message).fee)
	}
	
	func testVeryLongMessageFee() {
		let message = """
Lift you up again
Give you to the trees
All sound and visions are
What they ask of me

Let's run fast through the fields
Over mountaintops
Let's swim through ocean water
And we'll never stop

Just close your eyes
And pretend that everything's fine
Just close your eyes
I'll tell you when

Can you show me
Where to find the stream?
I've been told before
That the water's clean

Will you come with me?
Two of us can drink
Move quick, we've got to hurry
There's no time to think

Just close your eyes
And pretend that everything's fine
Just close your eyes
I'll tell you when

We didn't come this far
Just to turn around
We didn't come this far
Just to run away
Just ahead
We will hear the sound
The sound that gives us
A brand new day

Just close your eyes
And pretend that everything's fine
Just close your eyes
I'll tell you when

Mastodon / The Hunter / All The Heavy Lifting
Brann Timothy Dailor / Troy Jayson Sanders / William Breen Kelliher / William Brent Hinds
"""
		let estimatedFee = Decimal(0.004)
		
		XCTAssertEqual(estimatedFee, AdamantMessage.text(message).fee)
	}
}
