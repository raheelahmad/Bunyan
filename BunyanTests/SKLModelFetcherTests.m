//
//  SKLModelFetcherTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 4/20/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLCoreDataTests.h"

#import "SKLFakePerson.h"
#import "SKLFakeOpus.h"
#import "SKLPersonFetcher.h"

// Helpers and Mockers
#import "SKLTestableManagedObjectContext.h"
#import "SKLTestableAPIClient.h"
#import "SKLMockURLSession.h"

@interface SKLModelFetcherTests : SKLCoreDataTests

@property (nonatomic) SKLPersonFetcher *personFetcher;

@end

@implementation SKLModelFetcherTests

#pragma mark Refresh tests

- (void)testRefreshMakesCorrectEndpointAPIRequest {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @212;
	
	[self makePersonRefreshResponse:socrates];
	
	XCTAssertEqualObjects(self.personFetcher.mockApiClient.lastRequestPath, @"/get/persons/212", @"Refresh should be made with object's request info path");
}

- (void)testRefreshResponseUpdatesLocalObjects {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @210;
	
	[self makePersonRefreshResponse:socrates];
	
	NSDateComponents *dc = [[NSDateComponents alloc] init];
	dc.year = 2012; dc.month = 8; dc.day = 26; dc.hour = 19; dc.minute = 6; dc.second = 43;
	NSDate *socratesBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	
	[self checkForPersonWithId:@210 hasName:@"Socrates" location:@"Greece" birthdate:socratesBirthDate];
	
	SKLFakeOpus *magnum = socrates.magnumOpus;
	XCTAssertEqualObjects(magnum.name, @"The Republic", @"Refresh should update local object");
	XCTAssertEqualObjects(magnum.pageCount, @443, @"Refresh should update local object");
}


#pragma mark Fetch tests

- (void)testFetchMakesCorrectEndpointAPIRequest {
	[self.personFetcher fetchFromRemote];
	XCTAssertEqualObjects(self.personFetcher.mockApiClient.lastRequestPath, @"/get/persons", @"Fetch should be made with model request info path");
}

- (void)testFetchResponseCreatesLocalObjects {
	[self makePersonFetchResponse];
	
	NSArray *people = [SKLFakePerson allInContext:self.context];
	XCTAssertEqual([people count], (NSUInteger)2, @"Should insert objects after fetch");
}

- (void)testFetchResponseCreatesLocalObjectsWithRemoteValues {
	[self makePersonFetchResponse];
	
	NSDateComponents *dc = [[NSDateComponents alloc] init];
	dc.year = 2012; dc.month = 8; dc.day = 26; dc.hour = 19; dc.minute = 6; dc.second = 43;
	NSDate *platoBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	
	[self checkForPersonWithId:@126 hasName:@"Plato" location:@"Greece" birthdate:platoBirthDate];
	
	dc.year = 2010; dc.month = 02; dc.day = 06; dc.hour = 11; dc.minute = 36; dc.second = 49;
	NSDate *farabiBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	[self checkForPersonWithId:@120 hasName:@"Al Farabi" location:@"Persia" birthdate:farabiBirthDate];
    
    SKLFakePerson *plato = [[SKLFakePerson allInContext:self.context
											  predicate:[NSPredicate predicateWithFormat:@"remoteId  = %@", @126]] firstObject];
    XCTAssertEqualObjects(plato.name, @"Plato", @"");
}

- (void)testFetchDeletesStaleLocalObjectsIfInstructed {
	SKLFakePerson *person1 = [SKLFakePerson insertInContext:self.context];
	person1.name = @"Osho";
	[self makePersonFetchResponse];
	
	NSArray *all = [SKLFakePerson allInContext:self.context];
	XCTAssertEqual([all count], (NSInteger)2, @"Should delete stale objects");
	NSPredicate *oshoPredicate = [NSPredicate predicateWithFormat:@"name == %@", @"Osho"];
	NSInteger oshosLeftAfterUpdate = [[SKLFakePerson allInContext:self.context
													   predicate:oshoPredicate] count];
	XCTAssertEqual(0, oshosLeftAfterUpdate, @"Should delete stale objects");
}

- (void)testFetchResponseUpdatesExistingLocalObject {
	SKLFakePerson *platoEarlier = [SKLFakePerson insertInContext:self.context];
	platoEarlier.name = @"Plllaatoooo";
	platoEarlier.location = @"Crimea";
	platoEarlier.remoteId = @126; // remoteId will match the remote Plato object
	
	[self makePersonFetchResponse];
	
	NSPredicate *platoPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", @126];
	NSArray *allPlatos = [SKLFakePerson allInContext:self.context predicate:platoPredicate];
	XCTAssertEqual([allPlatos count], (NSUInteger)1, @"Update should match the existing object");
	SKLFakePerson *platoLater = [allPlatos firstObject];
	XCTAssertEqualObjects(platoLater, platoEarlier, @"Update should match the existing object");
	
	XCTAssertEqualObjects(platoEarlier.name, @"Plato", @"Update should match the existing object");
	
	SKLFakeOpus *magnumOpus = platoLater.magnumOpus;
	XCTAssertEqualObjects(magnumOpus.remoteId, @211, @"Update should update a to-one relationship");
	
	NSArray *otherOpuses = [platoLater.opuses allObjects];
	XCTAssertEqual([otherOpuses count], (NSUInteger)2, @"Update should update a to-many relationship");
}

- (void)testUpdateRespectsToManyRelationshipReplacement {
	SKLFakePerson *farabi = [SKLFakePerson insertInContext:self.context];
	
	SKLFakeOpus *opusOne = [SKLFakeOpus insertInContext:farabi.managedObjectContext];
	SKLFakeOpus *opusTwo = [SKLFakeOpus insertInContext:farabi.managedObjectContext];
	SKLFakeOpus *favOpusOne = [SKLFakeOpus insertInContext:farabi.managedObjectContext];
	SKLFakeOpus *favOpusTwo = [SKLFakeOpus insertInContext:farabi.managedObjectContext];
	// start with:
	//		two regular
	farabi.opuses = [NSSet setWithArray:@[ opusOne, opusTwo ]];
	//		two favorites
	farabi.favoriteOpuses = [NSSet setWithArray:@[ favOpusOne, favOpusTwo ]];
	
	NSArray *opuses = @[
						@{
							@"id" : @259, @"name" : @"Twilight Musings", @"pages" : @914
							},
						@{
							@"id" : @291, @"name" : @"Deen Aur Dua", @"pages" : @103
							}
						];
	NSArray *remoteFavoriteOpuses = @[
									  @{
										  @"id" : @219, @"name" : @"Errant Poetry", @"pages" : @914
										  },
									  @{
										  @"id" : @203, @"name" : @"Discussed Metaphors", @"pages" : @103
										  }
									  ];
    [self.personFetcher updateValueForObject:farabi localKey:@"opuses" remoteValue:opuses];
    [self.personFetcher updateValueForObject:farabi localKey:@"favoriteOpuses" remoteValue:remoteFavoriteOpuses];
	
	XCTAssertEqual([farabi.opuses count], (NSInteger)2, @"Should not retain previous to-many destination object if told so");
	XCTAssertFalse([farabi.opuses containsObject:opusOne], @"Should not retain previous to-many destination object if told so");
	XCTAssertFalse([farabi.opuses containsObject:opusTwo], @"Should not retain previous to-many destination object if told so");
	XCTAssertEqual([farabi.favoriteOpuses count], (NSInteger)4, @"Should retain previous to-many destination object if told so");
	XCTAssertTrue([farabi.favoriteOpuses containsObject:favOpusOne], @"Should retain previous to-many destination object if told so");
	XCTAssertTrue([farabi.favoriteOpuses containsObject:favOpusTwo], @"Should retain previous to-many destination object if told so");
}

#pragma mark Helpers

- (void)makePersonFetchResponse {
	self.context.shouldPerformBlockAsSync = YES;
	[self.personFetcher fetchFromRemote];
	
	NSArray *personFetchResponse = [self personFetchRemoteObjects];
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personFetchResponse options:0 error:nil];
	self.personFetcher.mockApiClient.mockSession.lastCompletionHandler(responseData, [self OKResponse], nil);
}

- (void)makePersonRefreshResponse:(SKLFakePerson *)person {
	self.context.shouldPerformBlockAsSync = YES;
	[self.personFetcher refreshObjectFromRemote:person];
	
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
	NSDictionary *personRefreshResponse = @{ @"id" : person.remoteId, @"name" : @"Socrates", @"location" : @"Greece", @"date" : @"2012-08-26T19:06:43Z",
										@"magnum" : @{
												@"id" : @211, @"name" : @"The Republic", @"pages" : @443
												},
										@"otherOpuses" : @[
                                                @{
													@"id" : @214, @"name" : @"Dramas", @"pages" : @204
													},
                                                @{
													@"id" : @204, @"name" : @"Interlooction", @"pages" : @123
													}
												]
                                        };
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personRefreshResponse options:0 error:nil];
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
															  statusCode:200
															 HTTPVersion:@"1.1"
															headerFields:jsonResponseHeaderDict];
	self.personFetcher.mockApiClient.mockSession.lastCompletionHandler(responseData, response, nil);
}


- (void)checkForPersonWithId:(NSNumber *)remoteId
					 hasName:(NSString *)name
					location:(NSString *)location
				   birthdate:(NSDate *)birthdate {
	NSPredicate *singlePersonPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", remoteId];
	SKLFakePerson *plato = [[SKLFakePerson allInContext:self.context predicate:singlePersonPredicate] firstObject];
	XCTAssertEqualObjects(plato.name, name, @"Remote fetch response should create local object with remote values");
	XCTAssertEqualObjects(plato.location, location, @"Remote fetch response should create local object with remote values");
	XCTAssertEqualObjects(plato.birthdate, birthdate, @"Remote fetch response should create local object with remote values");
}

- (NSArray *)personFetchRemoteObjects {
	return @[
			 @{ @"id" : @120, @"name" : @"Al Farabi", @"location" : @"Persia", @"date" : @"2010-02-06T11:36:49Z" },
			 @{ @"id" : @126, @"name" : @"Plato", @"location" : @"Greece", @"date" : @"2012-08-26T19:06:43Z",
				@"magnum" : @{
						@"id" : @211, @"name" : @"The Republic", @"pages" : @443
						},
				@"otherOpuses" : @[
						@{
							@"id" : @214, @"name" : @"Dramas", @"pages" : @204
							},
						@{
							@"id" : @204, @"name" : @"Interlooction", @"pages" : @123
							}
						]
				},
			 ];
	
}

- (NSHTTPURLResponse *)OKResponse {
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
															  statusCode:200
															 HTTPVersion:@"1.1"
															headerFields:jsonResponseHeaderDict];
	return response;
}


#pragma mark Setup

- (void)testModelsAreSetupCorrectlyInContext {
	SKLFakePerson *person = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SKLFakePerson class])
														  inManagedObjectContext:self.context];
	XCTAssertNotNil(person, @"SKLFakePerson is set up correctly");
	
	SKLFakeOpus *opus = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SKLFakeOpus class])
														  inManagedObjectContext:self.context];
	XCTAssertNotNil(opus, @"SKLFakeOpus is set up correctly");
}

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLFakePerson class])
												  attributes:[SKLFakePerson attributesForEntity]
										 ];
	NSEntityDescription *opusEntity = [self entityWithName:NSStringFromClass([SKLFakeOpus class])
												attributes:[SKLFakeOpus attributesForEntity]
									   ];
	addRelationships(personEntity, opusEntity, @"magnumOpus", @"magnumOwner", NO, NO);
	addRelationships(personEntity, opusEntity, @"favoriteOpuses", @"favoriteOwner", YES, NO);
	addRelationships(personEntity, opusEntity, @"opuses", @"owner", YES, NO);
	
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[ personEntity, opusEntity ];
    return model;
}

- (void)setUp {
    [super setUp];
	
	self.personFetcher = [[SKLPersonFetcher alloc] init];
	// Setup a mock API client for our PersonFetcher. This will mock the internal ModelFetcher apiClient accessor
	SKLTestableAPIClient *mockApiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://sakunlabs.com"];
	// the MockURLSession is what performs the mocking of URL requests, so we can easily inspect them after a request is made
	mockApiClient.mockSession = [[SKLMockURLSession alloc] init];
	self.personFetcher.mockApiClient = mockApiClient;
    self.personFetcher.mockImportContext = self.context;
}

- (void)tearDown {
    [super tearDown];
}

@end
