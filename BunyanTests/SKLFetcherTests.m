//
//  SKLFetcherTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLCoreDataTests.h"
#import "SKLTestableAPIClient.h"
#import "SKLManagedObject.h"
#import "SKLTestableManagedObjectContext.h"
#import "SKLAPIRequest.h"
#import "SKLAPIResponse.h"
#import "SKLMockURLSession.h"

// Dependency injected objects
SKLTestableAPIClient *apiClient;
SKLTestableManagedObjectContext *context;
BOOL shouldMockUpdateWithRemoteResponse;

// Returned objects
id responseObject;
NSError *error;

@class SKLFakeOpus;

// ----

@interface SKLFakePerson : SKLManagedObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *location;
@property (nonatomic) NSDate *birthdate;
@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) SKLFakeOpus *magnumOpus;
@property (nonatomic) NSSet *opuses;
@property (nonatomic) NSSet *favoriteOpuses;
@end

@implementation SKLFakePerson

@dynamic name, location, birthdate, remoteId, magnumOpus, opuses, favoriteOpuses;

+ (SKLAPIRequest *)remoteFetchInfo {
    return [SKLAPIRequest with:@"/get/persons" method:@"GET" params:nil body:nil];
}

+ (BOOL)shouldDelteStaleLocalObjects {
	return YES;
}

+ (SKLAPIClient *)apiClient {
	return apiClient;
}

- (SKLAPIRequest *)remoteRefreshInfo {
    NSString *endpoint = [NSString stringWithFormat:@"/get/persons/%@", self.remoteId];
	return [SKLAPIRequest with:endpoint method:@"GET" params:nil body:nil];
}

+ (void)updateWithRemoteFetchResponse:(NSArray *)response {
	if (shouldMockUpdateWithRemoteResponse) {
		responseObject = response;
	} else {
		[super updateWithRemoteFetchResponse:response];
	}
}

- (void)refreshWithRemoteResponse:(NSDictionary *)response {
	if (shouldMockUpdateWithRemoteResponse) {
		responseObject = response;
	} else {
		[super refreshWithRemoteResponse:response];
	}
}

+ (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"remoteId" : @"id",
			 @"name" : @"name",
			 @"location" : @"location",
			 @"birthdate" : @"date",
			 @"magnumOpus" : @"magnum",
			 @"opuses" : @"otherOpuses",
			 @"favoriteOpuses" : @"favorites",
			 };
}

- (id)localValueForKey:(NSString *)localKey RemoteValue:(id)remoteValue {
	id localValue = remoteValue;
	if ([localKey isEqualToString:@"birthdate"]) {
		// 2010-02-06T11:36:49Z
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		localValue = [df dateFromString:remoteValue];
	}
	return localValue;
}

+ (NSManagedObjectContext *)importContext {
	return context;
}

- (NSManagedObjectContext *)managedObjectContext {
	return context;
}

+ (id)uniquingKey {
	return @"remoteId";
}

- (BOOL)shouldReplaceWhenUpdatingToManyRelationship:(NSString *)relationship {
	if ([relationship isEqualToString:@"favoriteOpuses"]) {
		return NO; // i.e., keep existing to-many destination objects when setting
	} else {
		return YES;
	}
}

@end

@interface SKLFakeOpus : SKLManagedObject

@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *pageCount;
@property (nonatomic) SKLFakePerson *magnumOwner;
@property (nonatomic) SKLFakePerson *favoriteOwner;
@property (nonatomic) SKLFakePerson *owner;

@end

@implementation SKLFakeOpus

@dynamic name, pageCount, remoteId, magnumOwner, favoriteOwner, owner;

+ (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"name" : @"name",
			 @"remoteId" : @"id",
			 @"pageCount" : @"pages"
			 };
}

+ (id)uniquingKey { return @"remoteId"; }

@end


// ----

@interface SKLFetcherTests : SKLCoreDataTests

@property (nonatomic) SKLTestableAPIClient *apiClient;
@property (nonatomic) SKLMockURLSession *mockSession;

@end

@implementation SKLFetcherTests

#pragma mark - Refresh Tests

- (void)testRefreshMakesCorrectEndpointAPIRequest {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @212;
	
	[self makePersonRefreshResponse:socrates];
	
	XCTAssertEqualObjects(apiClient.lastRequestPath, @"/get/persons/212", @"Refresh should be made with object's request info path");
}

- (void)testRefreshResponseIsCalled {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @212;
	
	shouldMockUpdateWithRemoteResponse = YES;
	
	[self makePersonRefreshResponse:socrates];
	
	XCTAssertNotNil(responseObject, @"Fetch response should call the model on completion");
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


#pragma mark - Fetch Tests

- (void)testFetchMakesCorrectEndpointAPIRequest {
	[SKLFakePerson fetchFromRemote];
	XCTAssertEqualObjects(apiClient.lastRequestPath, @"/get/persons", @"Fetch should be made with model request info path");
}

- (void)testFetchResponseIsCalled {
	shouldMockUpdateWithRemoteResponse = YES;
	[self makePersonFetchResponse];
	XCTAssertNotNil(responseObject, @"Fetch response should call the model");
}

- (void)testFetchCompletionIsCalled {
    shouldMockUpdateWithRemoteResponse = YES;
    __block BOOL completionCalled = NO;
    [SKLFakePerson fetchFromRemoteWithCompletion:^(NSError *error) {
        completionCalled = YES;
    }];
    NSData *fakeData = [NSJSONSerialization dataWithJSONObject:@{ } options:0 error:nil];
    self.apiClient.mockSession.lastCompletionHandler(fakeData, nil, nil);
    XCTAssertTrue(completionCalled, @"Fetch should call the completion handler");
}

- (void)testFetchCustomCompletionIsCalled {
    SKLFakePerson *person = [SKLFakePerson insertInContext:self.context];
	SKLAPIRequest *request = [person remoteRefreshInfo];
	
	__block NSDictionary *receivedResponse;
	request.completionBlock = ^(NSError *error, SKLAPIResponse *apiResponse) {
		receivedResponse = apiResponse.responseObject;
	};
	NSDictionary *response = @{ @"name" : @"Thales" };
	
	[person refreshFromRemoteWithInfo:request];
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
	apiClient.mockSession.lastCompletionHandler(responseData, [self OKResponse], nil);
	
	XCTAssertEqualObjects(receivedResponse, response, @"Should call the custom completion block");
}

/**
 * A separate test from the rest:
 * Given that the APIRequest includes a wrappingKey then the whole remote response object
 * is wrapped in a dictionary with that key
 * E.g., the array below will be wrapped up in the key "disciples" before being passed to the completion
 */
- (void)testFetchResponseIsWrappedInProvidedKey {
	SKLAPIRequest *request = [SKLAPIRequest with:@"/please/go/here" method:@"GET" params:nil body:nil];
	request.responseWrappingKey = @"disciples";
	
	NSArray *disciplesResponse = @[
								   @{ @"name" : @"Tutoles" },
								   @{ @"name" : @"Boramius" },
								   ];
	NSError *error;
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:disciplesResponse
														   options:0 error:&error];
	
	request.completionBlock = ^(NSError *error, SKLAPIResponse *apiResponse) {
		NSArray *wrappedResponse = [apiResponse.responseObject valueForKey:@"disciples"];
		XCTAssertEqualObjects(disciplesResponse, wrappedResponse, @"");
	};
	[apiClient makeRequest:request];
	apiClient.mockSession.lastCompletionHandler(responseData, [self OKResponse], nil);
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
	[farabi updateValueForLocalKey:@"opuses" remoteValue:opuses];
	[farabi updateValueForLocalKey:@"favoriteOpuses" remoteValue:remoteFavoriteOpuses];
	
	XCTAssertEqual([farabi.opuses count], (NSInteger)2, @"Should not retain previous to-many destination object if told so");
	XCTAssertFalse([farabi.opuses containsObject:opusOne], @"Should not retain previous to-many destination object if told so");
	XCTAssertFalse([farabi.opuses containsObject:opusTwo], @"Should not retain previous to-many destination object if told so");
	XCTAssertEqual([farabi.favoriteOpuses count], (NSInteger)4, @"Should retain previous to-many destination object if told so");
	XCTAssertTrue([farabi.favoriteOpuses containsObject:favOpusOne], @"Should retain previous to-many destination object if told so");
	XCTAssertTrue([farabi.favoriteOpuses containsObject:favOpusTwo], @"Should retain previous to-many destination object if told so");
}

#pragma mark - Helpers

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

- (void)makePersonFetchResponse {
	self.context.shouldPerformBlockAsSync = YES;
	[SKLFakePerson fetchFromRemote];
	
	NSArray *personFetchResponse = [self personFetchRemoteObjects];
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personFetchResponse options:0 error:nil];
	apiClient.mockSession.lastCompletionHandler(responseData, [self OKResponse], nil);
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

- (void)makePersonRefreshResponse:(SKLFakePerson *)person {
	self.context.shouldPerformBlockAsSync = YES;
	[person refreshFromRemote];
	
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
	apiClient.mockSession.lastCompletionHandler(responseData, response, nil);
}


#pragma mark - Setup

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLFakePerson class])
												  attributes:@[
															   @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
															   @{ SKLAttrNameKey : @"location", SKLAttrTypeKey : @"string" },
															   @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
															   @{ SKLAttrNameKey : @"birthdate", SKLAttrTypeKey : @"date" }
															   ]
										 ];
	NSEntityDescription *opusEntity = [self entityWithName:NSStringFromClass([SKLFakeOpus class])
												attributes:@[
															 @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
															 @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
															 @{ SKLAttrNameKey : @"pageCount", SKLAttrTypeKey : @"int" }
															 ]
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
	
	shouldMockUpdateWithRemoteResponse = NO;
	context = self.context;
	self.apiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://sakunlabs.com"];
	self.apiClient.mockSession = [[SKLMockURLSession alloc] init];
	
	apiClient = self.apiClient;
}

- (void)tearDown {
	error = nil;
	self.context = nil;
	
	[super tearDown];
}

@end
