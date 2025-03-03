import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test community creation and limits",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Test creation as owner
    let block = chain.mineBlock([
      Tx.contractCall('game-guard', 'create-community', 
        [types.ascii("Test Community"), types.uint(2)], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Add members up to limit
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet1.address)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try adding beyond limit (should fail)
    const wallet2 = accounts.get('wallet_2')!;
    const wallet3 = accounts.get('wallet_3')!;
    
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet2.address)],
        deployer.address
      ),
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet3.address)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    block.receipts[1].result.expectErr().expectUint(104);
  }
});

Clarinet.test({
  name: "Test member removal and role updates",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create community and add member
    let block = chain.mineBlock([
      Tx.contractCall('game-guard', 'create-community',
        [types.ascii("Test Community"), types.uint(10)],
        deployer.address
      ),
      Tx.contractCall('game-guard', 'add-member',
        [types.uint(1), types.principal(wallet1.address)],
        deployer.address
      )
    ]);
    
    // Test valid role update
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'update-member-role',
        [types.uint(1), types.principal(wallet1.address), types.uint(2)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Test invalid role update
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'update-member-role',
        [types.uint(1), types.principal(wallet1.address), types.uint(4)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(105);
    
    // Test member removal
    block = chain.mineBlock([
      Tx.contractCall('game-guard', 'remove-member',
        [types.uint(1), types.principal(wallet1.address)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
