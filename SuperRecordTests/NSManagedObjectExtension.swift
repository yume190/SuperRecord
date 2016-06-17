//
//  NSManagedObjectExtension.swift
//  SuperRecord
//
//  Created by Piergiuseppe Longo on 20/11/14.
//  Copyright (c) 2014 Michael Armstrong. All rights reserved.
//

import UIKit
import CoreData
import XCTest
import SuperRecord

class NSManagedObjectExtension: SuperRecordTestCase {
   
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //MARK: Entity creation
    
    func testCreateNewEntity() {

        let fireType = Type.createNewEntity(managedObjectContext) as! Type;
        fireType.name = "Fire";
    
        let Charizard = Pokemon.createNewEntity(managedObjectContext) as! Pokemon;

        Charizard.id = PokemonID.charizard.rawValue
        Charizard.name = PokemonName.Charizard.rawValue
        Charizard.level = 36
        Charizard.type = fireType
    
        
        var expectation = self.expectation(withDescription: "Charizard Creation")
        var result = Pokemon.findAllWithPredicate(nil, context: managedObjectContext,  completionHandler:{error in
            expectation.fulfill();
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(result.count, 1,  "Should contains 1 pokemon");
        })
        
        let Charmender = Pokemon.createNewEntity(managedObjectContext) as! Pokemon;
        expectation = self.expectation(withDescription: "Charmender Creation")
        Charmender.id = PokemonID.charmender.rawValue
        Charmender.name = PokemonName.Charmender.rawValue
        Charmender.level = 1
        Charmender.type = fireType

        result = Pokemon.findAllWithPredicate(nil, context: managedObjectContext,  completionHandler:{error in
            expectation.fulfill();
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(result.count, 2,  "Should contains 2 pokemon");
        })
        
        XCTAssertEqual(fireType.pokemons.count, 2,  "Should contains 2 pokemon of this type");
        
        expectation = self.expectation(withDescription: "Pokemon Deletion")
        Pokemon.deleteAll(managedObjectContext)
        result = Pokemon.findAllWithPredicate(nil, context: managedObjectContext,  completionHandler:{error in
            expectation.fulfill();
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(result.count, 0,  "Should contains 0 pokemon");
        })
        
        XCTAssertEqual(fireType.pokemons.count, 0,  "Should contains 2 pokemon of this type");
    }
    
    func testFindFirstOrCreateWithAttribute(){

        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let Charizard  = PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);

        
        let charizardExpectation = expectation(withDescription: "Charizard creation")
        let anotherCharizard  = Pokemon.findFirstOrCreateWithAttribute("name", value: "Charizard", context: managedObjectContext, handler:{error in
            charizardExpectation.fulfill()
        }) as! Pokemon
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(Charizard, anotherCharizard, "Pokemon should be equals");
        })
        
        let Charmender  = Pokemon.findFirstOrCreateWithAttribute("name", value: "Charmender", context: managedObjectContext) as! Pokemon;

        XCTAssertNotNil(Charmender, "Pokemon should be not nil")
        XCTAssertNotEqual(Charizard, Charmender, "Pokemon should mismatch")
        managedObjectContext.delete(Charmender);
    }
    
    func testFindFirstOrCreateWithPredicate(){
        
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let Charizard  = PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);


        let predicate =  Predicate(format: "%K = %@", "name","Charizard")
        let charizardExpectation = expectation(withDescription: "Charizard creation")
        let anotherCharizard  = Pokemon.findFirstOrCreateWithPredicate(predicate, context: managedObjectContext, handler:{error in
            charizardExpectation.fulfill()
        }) as! Pokemon
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(Charizard, anotherCharizard, "Pokemon should be equals");
        })
        
        XCTAssertEqual(1, Pokemon.count(managedObjectContext, predicate: nil, error: nil), "Count mismatch")
        XCTAssertEqual(1, Type.count(managedObjectContext, predicate: nil, error: nil), "Count mismatch")
        
        let charmenderExpectation = expectation(withDescription: "Charmender creation")
        let charmenderPredicate = Predicate(format: "%K = %@", "name", "Charmender")

        let Charmender  = Pokemon.findFirstOrCreateWithPredicate(charmenderPredicate, context: managedObjectContext, handler:{error in
            charmenderExpectation.fulfill();
        }) as! Pokemon;
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertNotNil(Charmender, "Pokemon should be not nil")
            XCTAssertNotEqual(Charizard, Charmender, "Pokemon should mismatch")
        })
        
        managedObjectContext.delete(Charmender);
        
    }
    
    //MARK: Entity search
    
    func testFindAll(){
    
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)

        let charmender = PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        let charmeleon = PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        let charizard  = PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);
        
        var pokemons = Pokemon.findAll(managedObjectContext)
        
        XCTAssertEqual(3, pokemons.count, "Should contains 3 pokemons");
        XCTAssertTrue(pokemons.contains( charmender), "Should contains pokemon");
        XCTAssertTrue(pokemons.contains(charmeleon), "Should contains pokemon");
        XCTAssertTrue(pokemons.contains(charizard), "Should contains pokemon");

        let expectedPokemonArray = [charizard, charmeleon, charmender];
        var sortDescriptor = SortDescriptor(key: "level", ascending: false)
        pokemons = Pokemon.findAll(managedObjectContext, sortDescriptors: [sortDescriptor])
        XCTAssertEqual(expectedPokemonArray, pokemons, "Order mismatch")

        sortDescriptor = SortDescriptor(key: "level", ascending: true)
        pokemons = Pokemon.findAll(managedObjectContext, sortDescriptors: [sortDescriptor])
        
        XCTAssertEqual(Array(expectedPokemonArray.reversed()), pokemons, "Order mismatch")

        
    }
    
    func testFindAllWithAttribute(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)


        let charmender = PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        let charmeleon = PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        let charizard  = PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)

        
        var pokemons = Pokemon.findAllWithAttribute("name", value: charizard.name, context: managedObjectContext)
        XCTAssertEqual(1, pokemons.count, "Should contains 1 pokemons");
        
        pokemons = Pokemon.findAllWithAttribute("type", value: fireType, context: managedObjectContext)
        XCTAssertEqual(3, pokemons.count, "Should contains 3 pokemons");
        
        pokemons = Pokemon.findAllWithAttribute("type.name", value: fireType.name, context: managedObjectContext)
        XCTAssertEqual(3, pokemons.count, "Should contains 3 pokemons");
        
        var sortDescriptor = SortDescriptor(key: "level", ascending: false)
        let expectedPokemonArray = [charizard, charmeleon, charmender];
        pokemons = Pokemon.findAllWithAttribute("type.name", value: fireType.name, context: managedObjectContext, sortDescriptors: [sortDescriptor])
        XCTAssertEqual(expectedPokemonArray, pokemons, "Order mismatch")
        
        sortDescriptor = SortDescriptor(key: "level", ascending: true)
        pokemons = Pokemon.findAllWithAttribute("type.name", value: fireType.name, context: managedObjectContext, sortDescriptors: [sortDescriptor])
        XCTAssertEqual(Array(expectedPokemonArray.reversed()), pokemons, "Order mismatch")

    }
    
    func testFindAllWithPredicate(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)

        let charmender = PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        let charmeleon = PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);

        var predicate = Predicate (format: "level == %d", 36)
        var pokemons = Pokemon.findAllWithPredicate(predicate, context: managedObjectContext, completionHandler: nil)
        XCTAssertEqual(1, pokemons.count, "Should contains 1 pokemons");
        var sortDescriptor = SortDescriptor(key: "level", ascending: false)
        let expectedPokemonArray = [charmeleon, charmender];
        predicate = Predicate (format: "level < %d", 36)
        pokemons = Pokemon.findAllWithPredicate(predicate, context: managedObjectContext, sortDescriptors: [sortDescriptor], completionHandler: nil)
        XCTAssertEqual(expectedPokemonArray, pokemons, "Order mismatch")
        
        sortDescriptor = SortDescriptor(key: "level", ascending: true)
        pokemons = Pokemon.findAllWithPredicate(predicate, context: managedObjectContext, sortDescriptors: [sortDescriptor], completionHandler: nil)
        XCTAssertEqual(Array(expectedPokemonArray.reversed()), pokemons, "Order mismatch")
    }
        
    //MARK: Entity deletion
    
    func testDeleteAll(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)

        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);

        var pokemons = Pokemon.findAll (managedObjectContext);
        XCTAssertEqual(3, pokemons.count, "Should contains 3 pokemons");
        Pokemon.deleteAll(managedObjectContext)
        pokemons = Pokemon.findAll (managedObjectContext);
        XCTAssertEqual(0, pokemons.count, "Should contains 3 pokemons");
    }
    
    func testDeleteAllWithPredicate(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)

        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);

        var pokemons = Pokemon.findAll (managedObjectContext);
        XCTAssertEqual(3, pokemons.count, "Should contains 3 pokemons");
        let predicate = Predicate (format: "level == %d", 36)
        Pokemon.deleteAll(predicate, context: managedObjectContext)
        pokemons = Pokemon.findAll (managedObjectContext)
        XCTAssertEqual(2, pokemons.count, "Should contains 3 pokemons")

    }
    
    //MARK: Entity Update
    
    func testUpdateAllUsingPredicate(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Fire)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType);
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType);
        
        do {
            try managedObjectContext.save()
        } catch _ {
        };
    
        let levelPredicate = Predicate.predicateBuilder("level", value: 5, predicateOperator: NSPredicateOperator.GreaterThan);
        let typePredicate = Predicate.predicateBuilder("type", value: fireType, predicateOperator: NSPredicateOperator.Equal);
        let wrongTypePredicate = Predicate.predicateBuilder("type", value: waterType, predicateOperator: NSPredicateOperator.Equal);
        
        var updatedRows:Int = try! Pokemon.updateAll(managedObjectContext, propertiesToUpdate: ["level": 100], predicate: levelPredicate!, resultType: .updatedObjectsCountResultType) as! Int

        XCTAssertNil(error, "error shoul be nil")
        XCTAssertEqual(2, updatedRows, "Count mismatch")

        updatedRows = try! Pokemon.updateAll(managedObjectContext, propertiesToUpdate: ["level": 1], predicate: wrongTypePredicate!, resultType: .updatedObjectsCountResultType) as! Int
        
        XCTAssertNil(error, "error shoul be nil")
        XCTAssertEqual(0, updatedRows, "Count mismatch")

        updatedRows = try! Pokemon.updateAll(managedObjectContext, propertiesToUpdate: ["level": 100], predicate: typePredicate!, resultType: .updatedObjectsCountResultType) as! Int
        
        XCTAssertNil(error, "error shoul be nil")
        XCTAssertEqual(3, updatedRows, "Count mismatch")
    }
    
    //MARK: Entity operations
    
    func testCount(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)


        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)

        XCTAssertEqual(2, Type.count(managedObjectContext, predicate: nil, error: nil), "Count mismatch")
        
        XCTAssertEqual(4, Pokemon.count(managedObjectContext, predicate: nil, error: nil), "Count mismatch")
        var levelPredicate = Predicate(format: "level > 6");
        
        XCTAssertEqual(3, Pokemon.count(managedObjectContext, predicate: levelPredicate,  error: nil), "Count mismatch")
        
        levelPredicate = Predicate(format: "level > 36");
        XCTAssertEqual(0, Pokemon.count(managedObjectContext, predicate: levelPredicate,  error: nil), "Count mismatch")
        
        let typePredicate = Predicate(format: "%K = %@", "type", fireType);
        XCTAssertEqual(3, Pokemon.count(managedObjectContext, predicate: typePredicate,  error: nil),  "Count mismatch")

    }
    
    
    func testSum(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
    
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        let expectation = self.expectation(withDescription: "Sum")
        let sumLevel = Pokemon.sum(managedObjectContext, fieldName: "level", predicate: nil, handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
        XCTAssertEqual(89, sumLevel, "Count mismatch")
        })
        
        let sumsExpectation = self.expectation(withDescription: "Sum")
        var sumsLevel = Pokemon.sum(managedObjectContext, fieldName: ["level", "id"], predicate: nil,  handler:{error in
            sumsExpectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(89, sumsLevel[0], "Count mismatch")
            XCTAssertEqual(24, sumsLevel[1], "Count mismatch")
        })

    }
    
    func testSumGroupBy(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }

        let expectedLevels : [String : Double] = ["Fire" : 53, "Water" : 36]
    
        let sumsExpectation = expectation(withDescription: "Sum")
    
        let sumLevel = Pokemon.sum(managedObjectContext, fieldName: ["level"], predicate: nil, groupByField: ["type.name", "type.id"],  handler:{error in
            sumsExpectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            for dictionary in sumLevel  {
                let type = dictionary["type.name"] as AnyObject as! String
                let level = dictionary["level"]
                let expectedLevel = expectedLevels[type]
                XCTAssertEqual(expectedLevel, level)
            }
        })
     
    }
    
    func testMaxGroupBy(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        let expectedLevels : [String : Double] = ["Fire" : 36, "Water" : 36]
        
        let sumsExpectation = expectation(withDescription: "max")
        
        let sumLevel = Pokemon.max(managedObjectContext, fieldName: ["level"], predicate: nil, groupByField: ["type.name", "type.id"],  handler:{error in
            sumsExpectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            for dictionary in sumLevel  {
                let type = dictionary["type.name"] as AnyObject as! String
                let level = dictionary["level"]
                let expectedLevel = expectedLevels[type]
                XCTAssertEqual(expectedLevel, level)
            }
        })
        
    }

    
    func testMax(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        var expectation = self.expectation(withDescription: "Max")
        var max = Pokemon.max(managedObjectContext, fieldName: ["level"], predicate: nil, handler:{error in
            expectation.fulfill()
        }).first as Double!
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(36, max, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "Max")
        max = Pokemon.max(managedObjectContext, fieldName: "level", predicate: nil, handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(36, max, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "Max")
        max = Pokemon.max(managedObjectContext, fieldName: "level", predicate: Predicate(format: "level < 5"), handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(1, max, "Count mismatch")
        })

    }
    
    func testMinGroupBy(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        let expectedLevels : [String : Double] = ["Fire" : 1, "Water" : 36]
        
        let sumsExpectation = expectation(withDescription: "min")
        
        let sumLevel = Pokemon.min(managedObjectContext, fieldName: ["level"], predicate: nil, groupByField: ["type.name", "type.id"],  handler:{error in
            sumsExpectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            for dictionary in sumLevel  {
                let type = dictionary["type.name"] as AnyObject as! String
                let level = dictionary["level"]
                let expectedLevel = expectedLevels[type]
                XCTAssertEqual(expectedLevel, level)
            }
        })
        
    }
    
    func testMin(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        var expectation = self.expectation(withDescription: "min")
        var min = Pokemon.min(managedObjectContext, fieldName: ["level"], predicate: nil, handler:{error in
            expectation.fulfill()
        }).first as Double!
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(1, min, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "min")
        min = Pokemon.min(managedObjectContext, fieldName: "level", predicate: nil, handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(1, min, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "min")
        min = Pokemon.min(managedObjectContext, fieldName: "level", predicate: Predicate(format: "level >= 6"), handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(16, min, "Count mismatch")
        })
        
    }
    
    func testAvgGroupBy(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        let fireAvg : Double = Double(36 + 1 + 16) / 3;
        let expectedLevels : [String : Double] = ["Fire" : fireAvg , "Water" : 36]
        
        let sumsExpectation = expectation(withDescription: "avg")
        
        let sumLevel = Pokemon.avg(managedObjectContext, fieldName: ["level"], predicate: nil, groupByField: ["type.name", "type.id"],  handler:{error in
            sumsExpectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            for dictionary in sumLevel  {
                let type = dictionary["type.name"] as AnyObject as! String
                let level = dictionary["level"]
                let expectedLevel = expectedLevels[type]
                XCTAssertEqual(expectedLevel, level)
            }
        })
        
    }

    func testAvg(){
        let fireType = PokemonFactory.createType(managedObjectContext, id: .fire, name: .Fire)
        let waterType = PokemonFactory.createType(managedObjectContext, id: .water, name: .Water)
        
        PokemonFactory.createPokemon(managedObjectContext, id: .charmender, name: .Charmender, level: 1, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charmeleon, name: .Charmeleon, level: 16, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .charizard, name: .Charizard, level: 36, type: fireType)
        PokemonFactory.createPokemon(managedObjectContext, id: .blastoise, name: .Blastoise, level: 36, type: waterType)
        
        do {
            try managedObjectContext.save()
        } catch let error1 as NSError {
            error = error1
        }
        var expectation = self.expectation(withDescription: "avg")
        var avg = Pokemon.avg(managedObjectContext, fieldName: ["level"], predicate: nil, handler:{error in
            expectation.fulfill()
        }).first as Double!
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(22.25, avg, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "avg")
        avg = Pokemon.avg(managedObjectContext, fieldName: "level", predicate: nil, handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(22.25, avg, "Count mismatch")
        })
        
        expectation = self.expectation(withDescription: "avg")
        avg = Pokemon.avg(managedObjectContext, fieldName: "level", predicate: Predicate(format: "level >= 6"), handler:{error in
            expectation.fulfill()
        })
        
        waitForExpectations(timeout: SuperRecordTestCaseTimeout, handler: { error in
            XCTAssertEqual(88/3, avg, "Count mismatch")
        })
        
    }


    

}
